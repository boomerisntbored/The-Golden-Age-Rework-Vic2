// OPTIMIZACIÓN: Ruta relativa para evitar error de acceso (Access Violation)
texture tex0 < string name = "testred.dds"; >;

float4x4 WorldViewProjectionMatrix : WorldViewProjection;
float Zoom = 1.0f;

sampler2D BaseTexture = sampler_state
{
    Texture = <tex0>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear; // Usar Linear ayuda a evitar parpadeo al hacer zoom
    AddressU = Clamp;   // Clamp es mejor para widgets de UI que Wrap
    AddressV = Clamp;
};

struct VS_INPUT { float4 vPosition : POSITION; float2 vTexCoord : TEXCOORD0; };
struct VS_OUTPUT { float4 vPosition : POSITION; float2 vTexCoord : TEXCOORD0; };

VS_OUTPUT VertexShader_MapWidget(VS_INPUT v)
{
    VS_OUTPUT Out;
    Out.vPosition = mul(v.vPosition, WorldViewProjectionMatrix);

    // Zoom centrado (0.5 es el centro de la textura)
    float2 TexCoord = v.vTexCoord - 0.5f;
    TexCoord /= max(Zoom, 0.001f); // Evitamos división por cero si Zoom es 0
    TexCoord += 0.5f;

    Out.vTexCoord = TexCoord;
    return Out;
}

float4 PixelShader_MapWidget(VS_OUTPUT v) : COLOR
{
    float4 OutColor = tex2D(BaseTexture, v.vTexCoord);
    OutColor.a = 0.5f; // Transparencia fija
    return OutColor;
}

technique MapWidget
{
    pass p0
    {
        // Limpieza de estados antiguos: dejamos que el engine gestione el Blend
        AlphaBlendEnable = True;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;

        // Subido a vs_3_0 para evitar crasheos de registro en CPUs modernas
        VertexShader = compile vs_3_0 VertexShader_MapWidget();
        PixelShader = compile ps_2_0 PixelShader_MapWidget();
    }
}
