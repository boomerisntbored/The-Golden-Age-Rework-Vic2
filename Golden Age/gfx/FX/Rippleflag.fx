// Optimizamos las matrices usando una sola combinada (WorldViewProjection)
// Esto evita errores de desbordamiento en el Vertex Shader
float4x4 WorldViewProjectionMatrix : WorldViewProjection;

float4 FlagCoords;
float AnimationState;

sampler BaseTexture = sampler_state
{
    Texture = <tex0>;
    // Filtro Linear evita el parpadeo en movimiento (aliasing)
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_INPUT
{
    float4 vPosition  : POSITION;
    float2 vTexCoord  : TEXCOORD0;
    float4 vDiffuse   : COLOR; // Usamos vDiffuse.b para el desplazamiento
};

struct VS_OUTPUT
{
    float4 vPosition  : POSITION;
    float2 vTexCoord  : TEXCOORD0;
    float  vIntensity : TEXCOORD1; // Pasamos la intensidad calculada aquí
};

VS_OUTPUT OurVertexShader(VS_INPUT v)
{
    VS_OUTPUT Out;

    // Cálculo de la onda: 6.28318 es 2*PI
    float phase = -AnimationState + (v.vDiffuse.b * 6.28318f);
    float wave = 1.5f * v.vDiffuse.b * sin(phase);

    // Aplicar desplazamiento
    float4 InPosition = v.vPosition;
    InPosition.z += wave * 0.3f;

    // Transformación directa a espacio de proyección
    Out.vPosition = mul(InPosition, WorldViewProjectionMatrix);

    // Ajuste de coordenadas UV para el atlas (eficiente)
    Out.vTexCoord = (v.vTexCoord / FlagCoords.xy) + FlagCoords.zw;

    // Intensidad calculada en VS para ahorrar ciclos en PS
    Out.vIntensity = (sin(phase) * 0.2f) + 0.6f;

    return Out;
}

float4 OurPixelShader(VS_OUTPUT v) : COLOR
{
    float4 OutColor = tex2D(BaseTexture, v.vTexCoord);
    OutColor.rgb *= v.vIntensity; // Aplicamos el brillo variable

    return OutColor;
}

technique tec0
{
    pass p0
    {
        Lighting = False;
        AlphaBlendEnable = True;

        // vs_3_0 es mucho más robusto para cálculos de seno y matrices que vs_1_1
        VertexShader = compile vs_3_0 OurVertexShader();
        PixelShader = compile ps_2_0 OurPixelShader();
    }
}
