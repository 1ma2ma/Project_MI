    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

	float3 positionWS = vertexInput.positionWS;
	float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.positionWSAndFogFactor = float4(positionWS, fogFactor);

    output.normalWS = vertexNormalInput.normalWS; 
    output.positionCS = TransformWorldToHClip(positionWS);