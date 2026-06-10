// OPTIMIZACIÓN CRÍTICA: Matriz combinada.
// Multiplicar 'World * ViewProjection' por cada vértice destroza el rendimiento en procesadores modestos.
// Asegúrate de enviar la matriz ya multiplicada desde la CPU (C++/C#).
float4x4 WorldViewProjectionMatrix;

float SizeOffset, SizeFrame, Time, Selected;
float4 CountryColor, SelectionColor;

// --- Samplers (Condensados para ahorrar líneas) ---
texture BackgroundTex; sampler2D BackgroundSampler = sampler_state { Texture = <BackgroundTex>; AddressU=CLAMP; AddressV=CLAMP; MinFilter=Linear; MagFilter=Linear; };
texture MaskTex;       sampler2D MaskSampler       = sampler_state { Texture = <MaskTex>;       AddressU=CLAMP; AddressV=CLAMP; MinFilter=Linear; MagFilter=Linear; };
texture SizeTex;       sampler2D SizeSampler       = sampler_state { Texture = <SizeTex>;       AddressU=CLAMP; AddressV=CLAMP; MinFilter=Linear; MagFilter=Linear; };
texture CounterTex;    sampler2D CounterSampler    = sampler_state { Texture = <CounterTex>;    AddressU=CLAMP; AddressV=CLAMP; MinFilter=Linear; MagFilter=Linear; };

struct VS_INPUT { float3 Position : POSITION; float2 TexCoord : TEXCOORD0; };
struct VS_OUTPUT { float4 Position : POSITION; float2 TexCoord : TEXCOORD0; };

VS_OUTPUT Counter_VS( VS_INPUT In )
{
    VS_OUTPUT Out;
    // Ahora usamos una sola matriz precalculada
    Out.Position = mul( float4(In.Position, 1.0f), WorldViewProjectionMatrix );
    Out.TexCoord = In.TexCoord;
    return Out;
}

float4 Counter_PS( VS_OUTPUT In ) : COLOR
{
    // OPTIMIZACIÓN: tex2Dlod evita que la GPU integrada calcule mapas de bits intermedios (mipmaps),
    // lo cual es innecesario para contadores de UI en 2D y ahorra memoria.
    float4 CounterColor = tex2Dlod( CounterSampler, float4(In.TexCoord, 0.0f, 0.0f) );
    float4 BgColor      = tex2Dlod( BackgroundSampler, float4(In.TexCoord, 0.0f, 0.0f) );
    float4 MaskColor    = tex2Dlod( MaskSampler, float4(In.TexCoord, 0.0f, 0.0f) );

    float2 sizeUV       = float2( (In.TexCoord.x + SizeFrame) * SizeOffset, In.TexCoord.y );
    float4 SizeColor    = tex2Dlod( SizeSampler, float4(sizeUV, 0.0f, 0.0f) );

    // Cálculos limpios y directos
    float vMask = MaskColor.r;
    float SelectionAlpha = MaskColor.b * Selected;
    float SelectionIntensity = lerp(0.5f, 1.0f, abs(sin(Time * 2.0f)));

    // Mezcla de color base
    float4 FinalColor = float4(vMask * CountryColor.rgb * BgColor.rgb, BgColor.a);
    FinalColor.rgb = lerp(FinalColor.rgb, CounterColor.rgb, CounterColor.a);

    // RESTAURACIÓN DE CÓDIGO MUERTO: Ahora estas líneas sí se ejecutan,
    // devolviendo el brillo de selección original al juego sin hacer "llorar a Vista".
    FinalColor.rgb = lerp(FinalColor.rgb, SizeColor.rgb, SizeColor.a);
    FinalColor.rgb = FinalColor.rgb * (1.0f - SelectionAlpha) +
                     (MaskColor.g * SelectionColor.rgb * SelectionAlpha * SelectionIntensity);

    FinalColor.a += SelectionAlpha * Selected;

    return FinalColor;
}

technique Standard
{
    pass p0
    {
        ZENABLE = False;
        ZWRITEENABLE = False;
        ALPHATESTENABLE = False;
        ALPHABLENDENABLE = True;

        // Subimos el perfil para soportar tex2Dlod y un número mayor de instrucciones
        VertexShader = compile vs_3_0 Counter_VS();
        PixelShader = compile ps_3_0 Counter_PS();
    }
}
