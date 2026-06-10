float4x4 WorldViewProjectionMatrix;
float4x4 WorldMatrix; // Necesaria para transformar las normales

float4 LightDirection;
float4 LightColor = float4(1.0, 1.0, 1.0, 1.0);

texture tex0; // Agua
texture tex1; // Normal Map

sampler BaseSampler = sampler_state { Texture = <tex0>; MinFilter=Linear; MagFilter=Linear; AddressU=Wrap; AddressV=Wrap; };
sampler NormalSampler = sampler_state { Texture = <tex1>; MinFilter=Linear; MagFilter=Linear; AddressU=Wrap; AddressV=Wrap; };

struct VS_INPUT { float4 Position : POSITION; float3 Normal : NORMAL; float2 TexCoord : TEXCOORD0; };
struct VS_OUTPUT { float4 Position : POSITION; float2 TexCoord : TEXCOORD0; float3 WorldNormal : TEXCOORD1; };

VS_OUTPUT WaterVS(VS_INPUT In)
{
    VS_OUTPUT Out;
    Out.Position = mul(In.Position, WorldViewProjectionMatrix);
    Out.TexCoord = In.TexCoord;
    // Transformamos la normal al espacio del mundo
    Out.WorldNormal = mul(In.Normal, (float3x3)WorldMatrix);
    return Out;
}

float4 WaterPS(VS_OUTPUT In) : COLOR
{
    float3 normal = tex2D(NormalSampler, In.TexCoord).xyz * 2.0 - 1.0;
    float3 lightDir = normalize(LightDirection.xyz);

    // Iluminación simple (Lambert)
    float diff = max(dot(normalize(In.WorldNormal + normal), lightDir), 0.2);

    float4 waterColor = tex2D(BaseSampler, In.TexCoord);
    return float4(waterColor.rgb * diff * LightColor.rgb, waterColor.a);
}

technique WaterTechnique
{
    pass p0
    {
        Lighting = False; // Desactivamos el viejo motor de luz
        AlphaBlendEnable = True;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;

        VertexShader = compile vs_3_0 WaterVS();
        PixelShader = compile ps_3_0 WaterPS();
    }
}
