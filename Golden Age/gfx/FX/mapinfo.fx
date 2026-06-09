// --- Variables de Estado ---
float4x4 WorldViewProjectionMatrix;
float2   CameraPosition;
float4   ArrowColorAlpha;
float    IconTransparency;
float2   IconPosition;
float2   IconRotationSC; // <--- PASAR DESDE LA CPU: {cos(rad), sin(rad)}

texture tex0 : BodyTexture;
sampler2D BodyMap = sampler_state
{
    texture = <tex0>;
    AddressU = Clamp; AddressV = Clamp;
    MinFilter = Linear; MagFilter = Linear;
};

struct VS_OUTPUT_MAPINFO {
    float4 vPosition : POSITION;
    float2 vUV       : TEXCOORD0;
};

// Función maestra para evitar repetir código y ahorrar registros
float4 TransformIcon(float2 pos)
{
    float2 local = pos - IconPosition;
    // Rotación manual optimizada
    float2 rotated;
    rotated.x = (local.x * IconRotationSC.x) - (local.y * IconRotationSC.y);
    rotated.y = (local.y * IconRotationSC.x) + (local.x * IconRotationSC.y);

    return mul(float4(rotated.x + IconPosition.x - CameraPosition.x, 0.5f,
                      rotated.y + IconPosition.y - CameraPosition.y, 1.0f), WorldViewProjectionMatrix);
}

// --- Vertices ---
VS_OUTPUT_MAPINFO VertexMapInfo(float2 vPos : POSITION, float2 vUV : TEXCOORD0)
{
    VS_OUTPUT_MAPINFO Out;
    Out.vPosition = TransformIcon(vPos);
    Out.vUV = vUV;
    return Out;
}

VS_OUTPUT_MAPINFO VertexMapInfoText(float3 vPos : POSITION, float2 vUV : TEXCOORD0)
{
    VS_OUTPUT_MAPINFO Out;
    Out.vPosition = TransformIcon(vPos.xz); // Usamos xz porque es un plano de mapa
    Out.vUV = vUV;
    return Out;
}

// --- Pixel Shader ---
float4 PixelMapInfo(VS_OUTPUT_MAPINFO In) : COLOR
{
    float4 col = tex2D(BodyMap, In.vUV) * ArrowColorAlpha;
    col.a *= IconTransparency;
    return col;
}

// --- Técnicas (Estructura optimizada) ---
technique MapInfo {
    pass p0 {
        ZENABLE = True; ZWRITEENABLE = False; ALPHABLENDENABLE = True;
        CULLMODE = None;
        VertexShader = compile vs_2_0 VertexMapInfo();
        PixelShader = compile ps_2_0 PixelMapInfo();
    }
}

technique MapInfoText {
    pass p0 {
        ZENABLE = True; ZWRITEENABLE = False; ALPHABLENDENABLE = True;
        CULLMODE = None;
        VertexShader = compile vs_2_0 VertexMapInfoText();
        PixelShader = compile ps_2_0 PixelMapInfo();
    }
}
