texture tex0 < string name = "gfx/anims/railroad.dds"; >;

float4x4    ViewProjectionMatrix;
float4      ControlPoints[2];
float4      TotalVertices_Length_Pos;

sampler BaseTexture = sampler_state
{
    Texture = <tex0>;
    MinFilter = Linear; MagFilter = Linear; MipFilter = Linear;
    MipMapLodBias = -1;
    AddressU = Wrap; AddressV = Wrap; AddressW = Wrap;
};

struct VS_INPUT { float2 vPosition : POSITION; };
struct VS_OUTPUT { float4 vPosition : POSITION; float2 vUV : TEXCOORD0; };

VS_OUTPUT RailroadVS(const VS_INPUT v)
{
    VS_OUTPUT Out;

    float t = v.vPosition.x / TotalVertices_Length_Pos.x;
    float t2 = t * t;
    float t3 = t2 * t;

    // Vectorizamos los puntos para usar instrucciones simultáneas (SIMD)
    float2 p0 = ControlPoints[0].xy;
    float2 p1 = ControlPoints[0].zw;
    float2 p2 = ControlPoints[1].xy;
    float2 p3 = ControlPoints[1].zw;

    // Pre-calculamos los coeficientes del polinomio de la curva
    float2 c0 = 2.0f * p1;
    float2 c1 = p2 - p0;
    float2 c2 = 2.0f * p0 - 5.0f * p1 + 4.0f * p2 - p3;
    float2 c3 = -p0 + 3.0f * p1 - 3.0f * p2 + p3;

    // 1. Calculamos la posición exacta usando los vectores (float2)
    float2 pos2D = (c3 * t3 + c2 * t2 + c1 * t + c0) * 0.5f;

    // 2. OPTIMIZACIÓN EXTREMA: Derivada analítica para la tangente.
    // Evita tener que recalcular la posición en t + 0.005f
    // Derivada de t^3 es 3t^2, de t^2 es 2t. (Ignoramos el *0.5f porque vamos a normalizar)
    float2 tangent = (3.0f * c3 * t2) + (2.0f * c2 * t) + c1;

    // La normal 2D perpendicular a la tangente es (-y, x)
    float2 normal = normalize(float2(-tangent.y, tangent.x));

    // Construimos la posición 3D
    float4 vPos = float4(pos2D.x, 0.38f, pos2D.y, 1.0f);

    // Aplicamos el ancho de la vía usando la normal exacta
    vPos.xz += normal * (v.vPosition.y * 0.8f);
    vPos.xz -= TotalVertices_Length_Pos.zw;

    Out.vPosition = mul(vPos, ViewProjectionMatrix);
    Out.vUV = float2(t * TotalVertices_Length_Pos.y, v.vPosition.y + 0.5f);

    return Out;
}

float4 RailroadPS(VS_OUTPUT v) : COLOR
{
    // El Pixel Shader ya era perfecto, retornamos la textura directamente
    return tex2D(BaseTexture, v.vUV);
}

technique railroad
{
    pass p0
    {
        ALPHABLENDENABLE = True;
        // Subimos a la versión 3_0 para aprovechar mejor los registros del Celeron
        VertexShader = compile vs_3_0 RailroadVS();
        PixelShader = compile ps_3_0 RailroadPS();
    }
}
