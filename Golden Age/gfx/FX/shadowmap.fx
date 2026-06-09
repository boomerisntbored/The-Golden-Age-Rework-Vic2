float4x4 WorldViewMatrix;
float4x4 ProjectionMatrix;
float4x4 ViewToLightProjectionMatrix;
texture ShadowTexture;

sampler2D SamplerShadow =
sampler_state
{
    Texture = <ShadowTexture>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Clamp;
    AddressV = Clamp;
};

// --- RenderShadow ---
// Dejamos la técnica, pero el shader hace lo mínimo necesario
void VertShadow( float4 Pos : POSITION, out float4 oPos : POSITION )
{
    oPos = mul(Pos, WorldViewMatrix);
    oPos = mul(oPos, ProjectionMatrix);
}

float4 PixShadow( float2 Depth : TEXCOORD0 ) : COLOR
{
    return float4(0, 0, 0, 0); // No renderiza nada
}

technique RenderShadow
{
    pass p0
    {
        VertexShader = compile vs_2_0 VertShadow();
        PixelShader = compile ps_2_0 PixShadow();
    }
}

// --- RenderShadowToScene ---
void VertShadowToScene( float4 Pos : POSITION,
                        float3 Normal : NORMAL,
                        out float4 oPos : POSITION,
                        out float4 vPos : TEXCOORD0,
                        out float4 vPosLight : TEXCOORD1 )
{
    vPos = mul(Pos, WorldViewMatrix);
    oPos = mul(vPos, ProjectionMatrix);
    vPosLight = 0; // Eliminamos el cálculo de la matriz de luz para evitar carga innecesaria
}

float4 PixShadowToScene( float4 vPos : TEXCOORD0,
                         float4 vPosLight : TEXCOORD1 ) : COLOR
{
    // RETORNAMOS UN VALOR NEUTRO
    // Al retornar 1.0, el sombreado desaparece completamente de la escena
    return float4(1.0f, 1.0f, 1.0f, 1.0f);
}

technique RenderShadowToScene
{
    pass p0
    {
        VertexShader = compile vs_2_0 VertShadowToScene();
        PixelShader = compile ps_2_0 PixShadowToScene();
    }
}
