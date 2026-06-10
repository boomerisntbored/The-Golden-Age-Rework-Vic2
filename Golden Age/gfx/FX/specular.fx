float4x4 WorldViewProjectionMatrix : WorldViewProjection;
float4x4 WorldMatrix                : World;
float4x4 WorldViewMatrix            : WorldView;

float4 LightDirection;
float4 LightAmbient;
float4 LightColor;
float3 CameraPosition;

float4 Color1, Color2, Color3;

// Optimizamos samplers eliminando el MipFilter innecesario en UI/objetos fijos
sampler2D DiffuseTexture = sampler_state { texture = <tex0>; AddressU=CLAMP; AddressV=CLAMP; MinFilter=Linear; MagFilter=Linear; };
sampler2D ColorTexture   = sampler_state { texture = <tex1>; AddressU=CLAMP; AddressV=CLAMP; MinFilter=Linear; MagFilter=Linear; };

struct VS_INPUT { float4 Position : POSITION; float2 TexCoord : TEXCOORD0; float3 Normal : NORMAL; };

struct VS_OUTPUT
{
    float4 Position  : POSITION;
    float2 TexCoord  : TEXCOORD0;
    float3 Normal    : TEXCOORD1;
    float3 ViewDir   : TEXCOORD3;
};

VS_OUTPUT Object_VertexShader( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = mul(In.Position, WorldViewProjectionMatrix);

    // Transformamos normal al espacio de mundo.
    // Usamos float3x3 para evitar errores de perspectiva innecesarios.
    Out.Normal = normalize(mul(In.Normal, (float3x3)WorldMatrix));

    // Calculamos dirección de vista en el VS para ahorrar instrucciones en el PS
    float3 worldPos = mul(In.Position, WorldMatrix).xyz;
    Out.ViewDir = normalize(CameraPosition - worldPos);

    Out.TexCoord = In.TexCoord;
    return Out;
}

// Función compartida para iluminación (reduce duplicación de código)
float3 CalculateLighting(float3 normal, float3 viewDir, float4 diffuse)
{
    float3 L = normalize(-LightDirection.xyz);
    float diff = saturate(dot(normal, L));

    float3 H = normalize(viewDir + L);
    float spec = pow(saturate(dot(normal, H)), 64.0);

    return (diffuse.rgb * LightAmbient.rgb) + (diffuse.rgb * diff * LightColor.rgb) + (spec * diffuse.a);
}

float4 PS_Base( VS_OUTPUT In ) : COLOR
{
    float4 Diffuse = tex2D( DiffuseTexture, In.TexCoord );
    float3 finalRGB = CalculateLighting(normalize(In.Normal), normalize(In.ViewDir), Diffuse);
    return float4(finalRGB, 1.0f);
}

float4 PS_Color( VS_OUTPUT In ) : COLOR
{
    float4 Diffuse = tex2D( DiffuseTexture, In.TexCoord );
    float4 Colors = tex2D( ColorTexture, In.TexCoord );

    // Aplicamos los tintes según los canales RGB de la máscara
    Diffuse.rgb += Colors.r * Color1.rgb;
    Diffuse.rgb += Colors.g * Color2.rgb;
    Diffuse.rgb += Colors.b * Color3.rgb;

    float3 finalRGB = CalculateLighting(normalize(In.Normal), normalize(In.ViewDir), Diffuse);
    return float4(finalRGB, 1.0f);
}

technique spec
{
    pass p0
    {
        VertexShader = compile vs_3_0 Object_VertexShader();
        PixelShader = compile ps_2_0 PS_Base();
    }
}

technique spec_color
{
    pass p0
    {
        VertexShader = compile vs_3_0 Object_VertexShader();
        PixelShader = compile ps_2_0 PS_Color();
    }
}
