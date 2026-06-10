// OPTIMIZACIÓN 1: Ruta relativa (Quita la ruta C:\\ absoluta)
// Si el archivo está en la misma carpeta, solo pon el nombre del archivo.
texture tex0 < string name = "testred.dds"; >;

float4x4 WorldViewProjectionMatrix;
float CurrentProgress;
float2 CameraPosition;

sampler BaseTexture = sampler_state
{
    Texture = <tex0>;
    // OPTIMIZACIÓN 2: Simplificación del filtrado para evitar fallos de driver
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_INPUT
{
    float4 vPosition : POSITION;
    float2 vProgress : TEXCOORD0;
    float2 vTexCoord : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4 vPosition : POSITION;
    float2 vTexCoord : TEXCOORD1;
    float  vProgress : TEXCOORD0;
};

VS_OUTPUT VertexShader_Arrow(const VS_INPUT v)
{
    VS_OUTPUT Out;

    // Aplicamos el desplazamiento de cámara
    float4 vPos = v.vPosition;
    vPos.x -= CameraPosition.x;
    vPos.z -= CameraPosition.y;

    Out.vPosition = mul(vPos, WorldViewProjectionMatrix);

    // Pre-calculamos el factor de progreso para que el Pixel Shader trabaje menos
    Out.vProgress = saturate((CurrentProgress - v.vProgress.x) * 50.0f);
    Out.vTexCoord = v.vTexCoord;

    return Out;
}

float4 PixelShader_Arrow(VS_OUTPUT v) : COLOR
{
    // Muestreo de las dos texturas
    float4 color1 = tex2D(BaseTexture, v.vTexCoord);
    float4 color2 = tex2D(BaseTexture, float2(v.vTexCoord.x, v.vTexCoord.y + 0.5f));

    // Mezcla suave
    return lerp(color1, color2, v.vProgress);
}

technique tec0
{
    pass p0
    {
        ALPHABLENDENABLE = True;
        ALPHATESTENABLE = True;
        ZWRITEENABLE = False;

        // OPTIMIZACIÓN 3: Subida a perfiles más estables
        VertexShader = compile vs_3_0 VertexShader_Arrow();
        PixelShader = compile ps_3_0 PixelShader_Arrow();
    }
}
