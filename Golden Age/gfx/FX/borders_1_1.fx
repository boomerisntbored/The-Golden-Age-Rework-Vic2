// Declaración de texturas simplificada
texture tex0 < string ResourceName = "borders.tga"; >;
texture tex1 < string ResourceName = "borderDirections.tga"; >;

float4x4 WorldViewProjection; // Optimizacion: Usar una sola matriz evita calcular multiplicaciones en el shader

sampler BaseTexture = sampler_state
{
    Texture = <tex0>;
    MinFilter = Linear; MagFilter = Linear; MipFilter = None;
    AddressU = Wrap; AddressV = Wrap;
};

struct VS_INPUT {
    float4 vPosition : POSITION;
    float2 vTexCoord : TEXCOORD0;
};

struct VS_OUTPUT {
    float4 vPosition : POSITION;
    float2 vTexCoord0 : TEXCOORD0;
};

// --- Vertex Shader ---
// Eliminamos mul(World, View) y calculamos todo en una sola matriz (WorldViewProjection)
// Esto ahorra 12+ instrucciones por cada vértice.
VS_OUTPUT VertexShader_Border(const VS_INPUT v)
{
    VS_OUTPUT Out;
    Out.vPosition = mul(v.vPosition, WorldViewProjection);
    Out.vTexCoord0 = v.vTexCoord;
    return Out;
}

// --- Pixel Shader ---
// Optimizacion: Reduccion de registros y asignacion directa
float4 PixelShader_Border(VS_OUTPUT v) : COLOR
{
    float4 BaseColor = tex2D(BaseTexture, v.vTexCoord0);

    // Devolvemos el color directamente sin declarar variables intermedias inútiles
    // Esto ahorra espacio en los registros del shader.
    return float4(BaseColor.r, 0.1f, 0.1f, BaseColor.b);
}

technique BorderShader
{
    pass p0
    {
        ALPHABLENDENABLE = True;
        VertexShader = compile vs_1_1 VertexShader_Border();
        PixelShader = compile ps_1_1 PixelShader_Border();
    }
}
