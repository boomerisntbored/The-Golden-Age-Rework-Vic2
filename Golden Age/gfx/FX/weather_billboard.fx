float vXOffset;
float vTime;

float4x4 WorldViewProjectionMatrix; // Recomendación: pasar la matriz ya multiplicada

sampler2D WeatherSampler = sampler_state
{
    Texture = <tex0>;
    AddressU = WRAP; AddressV = WRAP;
    MinFilter = Linear; MagFilter = Linear;
};

struct VS_INPUT { float3 Position : POSITION; float2 TexCoord : TEXCOORD0; };
struct VS_OUTPUT { float4 Position : POSITION; float2 TexCoord : TEXCOORD0; float2 OffsetUV : TEXCOORD1; };

VS_OUTPUT Weather_VS( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = mul(float4(In.Position, 1.0f), WorldViewProjectionMatrix);
    Out.TexCoord = In.TexCoord;

    // Calculamos el movimiento aquí para no hacerlo miles de veces en el Pixel Shader
    float vATimeRain = -vTime * 0.000025f; // Factor optimizado
    float vATimeSnow = -vTime * 0.00001f;

    // Pasamos el offset calculado como un interpolador
    Out.OffsetUV = float2(vXOffset + (sin(vATimeSnow * 9.42f) * 0.01f), vATimeRain);

    return Out;
}

float4 Rain_PS( VS_OUTPUT In ) : COLOR
{
    // Muestreo simple: las texturas de lluvia suelen ser repetitivas, el filtrado lineal basta
    float4 Color = tex2D( WeatherSampler, In.TexCoord + In.OffsetUV );
    return Color;
}

float4 Snow_PS( VS_OUTPUT In ) : COLOR
{
    float4 Color = tex2D( WeatherSampler, In.TexCoord + In.OffsetUV );
    return Color;
}

technique RainTech
{
    pass p0
    {
        ZENABLE = False; ZWRITEENABLE = False; ALPHABLENDENABLE = True;
        VertexShader = compile vs_3_0 Weather_VS();
        PixelShader = compile ps_2_0 Rain_PS();
    }
}

technique SnowTech
{
    pass p0
    {
        ZENABLE = False; ZWRITEENABLE = False; ALPHABLENDENABLE = True;
        VertexShader = compile vs_3_0 Weather_VS();
        PixelShader = compile ps_2_0 Snow_PS();
    }
}
