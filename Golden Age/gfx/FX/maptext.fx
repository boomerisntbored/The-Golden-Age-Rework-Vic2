texture tex0 < string name = "sdf"; >;

float4x4 WorldViewProjectionMatrix;
float CurrentState; // Usado para el desplazamiento vertical

sampler BaseTexture = sampler_state
{
    Texture = <tex0>;
    // Cambiado a Linear para suavizar la textura al moverse
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_INPUT
{
    float4 vPosition  : POSITION;
    float4 vDiffuse   : COLOR;
    float2 vTexCoord  : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 vPosition   : POSITION;
    float2 vTexCoord0  : TEXCOORD0;
    float4 vDiffuse    : COLOR;
};

VS_OUTPUT VertexShader(const VS_INPUT v)
{
    VS_OUTPUT Out;

    // Transformación directa con la matriz WVP (la más eficiente)
    Out.vPosition = mul(v.vPosition, WorldViewProjectionMatrix);

    // Optimizamos el cálculo de la coordenada:
    // Usamos saturación para evitar cálculos de 'min' innecesarios
    Out.vTexCoord0 = v.vTexCoord;
    Out.vTexCoord0.y = saturate(v.vTexCoord.y + CurrentState);

    Out.vDiffuse = v.vDiffuse;

    return Out;
}

float4 PixelShader(VS_OUTPUT v) : COLOR
{
    float4 OutColor = tex2D(BaseTexture, v.vTexCoord0);
    // Multiplicación directa del alfa
    OutColor.a *= v.vDiffuse.a;

    return OutColor;
}

technique tec0
{
    pass p0
    {
        // En vs_3_0, ya no necesitamos definir el FVF manualmente en el shader
        Lighting = False;
        AlphaBlendEnable = True;
        SrcBlend = SrcAlpha;
        DestBlend = InvSrcAlpha;

        VertexShader = compile vs_3_0 VertexShader();
        PixelShader = compile ps_2_0 PixelShader();
    }
}
