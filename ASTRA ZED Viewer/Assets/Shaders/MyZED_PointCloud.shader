//======= Copyright (c) Stereolabs Corporation, All rights reserved. ===============
//Displays point cloud though geometry
Shader "MyZED PointCloud"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Size("Size", Range(0.1,2)) = 0.1
		_PointSize("Point Size", Float) = 0.05
	}
	SubShader
	{


		Pass
		{
			Cull Off
			CGPROGRAM
			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag
            #pragma geometry Geometry


			#include "UnityCG.cginc"
			

			struct PS_INPUT
			{
				float4 position : SV_POSITION;
				float4 color : COLOR;
				float3 normal : NORMAL;

			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _XYZTex;
			sampler2D _ColorTex;
			float4 _XYZTex_TexelSize;
			float4x4 _Position;

			float _Size;
			half _PointSize;

			PS_INPUT vert (appdata_full v, uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
			{
				PS_INPUT o;
				o.normal = v.normal;

				//Compute the UVS
				float2 uv = float2(
							clamp(fmod(instance_id, _XYZTex_TexelSize.z) * _XYZTex_TexelSize.x, _XYZTex_TexelSize.x, 1.0 - _XYZTex_TexelSize.x),
							clamp(((instance_id -fmod(instance_id, _XYZTex_TexelSize.z) * _XYZTex_TexelSize.x) / _XYZTex_TexelSize.z) * _XYZTex_TexelSize.y, _XYZTex_TexelSize.y, 1.0 - _XYZTex_TexelSize.y)
							);

				


				//Load the texture
				float4 XYZPos = float4(tex2Dlod(_XYZTex, float4(uv, 0.0, 0.0)).rgb ,1.0f);

				//Set the World pos
				o.position = mul(mul(UNITY_MATRIX_VP, _Position ), XYZPos);

				o.color =  float4(tex2Dlod(_ColorTex, float4(uv, 0.0, 0.0)).bgr ,1.0f);

				return o;
			}

			struct gs_out {
				float4 position : SV_POSITION;
				float4 color : COLOR;
			};


			
			fixed4 frag (PS_INPUT i) : SV_Target
			{
				return i.color;
			}

			// Geometry phase
			[maxvertexcount(36)]
			void Geometry(point PS_INPUT input[1], inout TriangleStream<PS_INPUT> outStream)
			{
				float4 cam_pos = mul(mul(UNITY_MATRIX_VP, _Position ), float4(0.0, 0.0, 0.0, 1.0));
				float4 origin = input[0].position;
				float cam_dist = distance(origin,cam_pos);
				float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize * cam_dist);

				// Copy the basic information.
				PS_INPUT o = input[0];

				// Determine the number of slices based on the radius of the
				// point on the screen.
				float radius = extent.y / origin.w * _ScreenParams.y;
				uint slices = min((radius + 1) / 5, 4) + 2;

				// Slightly enlarge quad points to compensate area reduction.
				if (slices == 2) extent *= 1.2;

				// Top vertex
				o.position.y = origin.y + extent.y;
				o.position.xzw = origin.xzw;
				outStream.Append(o);

				UNITY_LOOP for (uint i = 1; i < slices; i++)
				{
					float sn, cs;
					sincos(UNITY_PI / slices * i, sn, cs);

					// Right side vertex
					o.position.xy = origin.xy + extent * float2(sn, cs);
					outStream.Append(o);

					// Left side vertex
					o.position.x = origin.x - extent.x * sn;
					outStream.Append(o);
				}

				// Bottom vertex
				o.position.x = origin.x;
				o.position.y = origin.y - extent.y;
				outStream.Append(o);

				outStream.RestartStrip();
			}
			
			ENDCG
		}
	}
}
