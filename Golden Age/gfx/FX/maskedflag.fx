texture tex0;
texture tex1;

float4x4 WorldViewProjectionMatrix : WorldViewProjection;
float4 FlagCoords;

// Optimizamos el filtrado a Linear para suavizado de bordes en UI
sampler2D BaseTexture = sampler_state { Texture = <tex0>; MinFilter = Linear; MagFilter = Linear; AddressU = Clamp; AddressV = Clamp; };
sampler2D MaskTexture = sampler_state { Texture = <tex1>; MinFilter = Linear; MagFilter = Linear; AddressU = Clamp; AddressV = Clamp; };

struct VS_INPUT { float4 vPosition : POSITION; float2 vTexCoord : TEXCOORD0; float2 vMaskCoord : TEXCOORD1; };
struct VS_OUTPUT { float4 vPosition : POSITION; float2 vTexCoord0 : TEXCOORD0; float2 vTexCoord1 : TEXCOORD1; };

VS_OUTPUT OurVertexShader(VS_INPUT v)
{
    VS_OUTPUT Out;
    Out.vPosition = mul(v.vPosition, WorldViewProjectionMatrix);
    // Cálculo simplificado de coordenadas de textura
    Out.vTexCoord0 = (v.vTexCoord / FlagCoords.xy) + FlagCoords.zw;
    Out.vTexCoord1 = v.vMaskCoord;
    return Out;
}

// Función centralizada para aplicar el efecto de máscara
float4 ApplyBase(float2 uv, float2 maskUV, float4 mix, bool desaturate)
{
    float4 col = tex2D(BaseTexture, uv);
    float4 mask = tex2D(MaskTexture, maskUV);

    if (desaturate) {
        float grey = dot(col.rgb, float3(0.212671f, 0.715160f, 0.072169f));
        col.rgb = grey;
    } else {
        col.rgb += mix.rgb;
    }

    col.a = mask.a;
    return col;
}

float4 PS_Normal(VS_OUTPUT v) : COLOR { return ApplyBase(v.vTexCoord0, v.vTexCoord1, float4(0,0,0,0), false); }
float4 PS_Over(VS_OUTPUT v)   : COLOR { return ApplyBase(v.vTexCoord0, v.vTexCoord1, float4(0.1, 0.1, 0.1, 0), false); }
float4 PS_Down(VS_OUTPUT v)   : COLOR { return ApplyBase(v.vTexCoord0, v.vTexCoord1, float4(-0.1, -0.1, -0.1, 0), false); }
float4 PS_Disable(VS_OUTPUT v): COLOR { return ApplyBase(v.vTexCoord0, v.vTexCoord1, float4(0,0,0,0), true); }

technique tec0    { pass p0 { VertexShader = compile vs_3_0 OurVertexShader(); PixelShader = compile ps_2_0 PS_Normal(); } }
technique over    { pass p0 { VertexShader = compile vs_3_0 OurVertexShader(); PixelShader = compile ps_2_0 PS_Over(); } }
technique down    { pass p0 { VertexShader = compile vs_3_0 OurVertexShader(); PixelShader = compile ps_2_0 PS_Down(); } }
technique disable { pass p0 { VertexShader = compile vs_3_0 OurVertexShader(); PixelShader = compile ps_2_0 PS_Disable(); } }
