{
    "openapi": "3.0.0",
    "info": {
        "version": "1.0.0",
        "title": "Custom API",
        "description": "This is the place to add your own path endpoints"
    },
    "servers": [
        {
            "description": "Endpoint for testing on localhost",
            "url": "/exist/apps/tei-publisher"
        }
    ],
    "components": {
        "securitySchemes": {
            "basicAuth": {
                "type": "http",
                "scheme": "basic"
            },
            "cookieAuth": {
                "type": "apiKey",
                "name": "teipublisher.com.login",
                "in": "cookie"
            }
        }
    },
    "paths": {"/api/status/{path}": {
			"post": {
				"summary": "Merge status into source TEI",
				"tags": ["status"],
				"operationId": "custom:status-save",
				"requestBody": {
					"description": "Status of work of the document will be saved into metadata",
					"content": {
						"application/json": {
							"schema": {
								"type": "array",
								"items": {
									"type": "object",
									"properties": {
										"context": {
											"type": "string"
										},
										"start": {
											"type": "number"
										},
										"end": {
											"type": "number"
										},
										"type": {
											"type": "string"
										},
										"text": {
											"type": "string"
										},
										"properties": {
											"type": "object"
										}
									}
								}
							}
						}
					}
				},
				"parameters": [
					{
						"name": "path",
						"in": "path",
						"description": "Relative path to the TEI document to be changed",
						"schema": {
							"type": "string",
							"example": "annotate/bach_test2.xml"
						},
						"required": true
					},
					{
						"name": "status",
						"in": "query",
						"description": "Status of the document.",
						"schema": {
							"type": "string"
						}
					}
				],
				"responses": {
					"200": {
						"description": "Returns the merged TEI XML",
						"content": {
							"application/json": {
								"schema": {
									"type": "object"
								}
							}
						}
					}
				}
			},
			"put": {
				"summary": "Merge status into source TEI and store the resulting document",
				"tags": ["status"],
				"operationId": "custom:status-save",
				"x-constraints": {
					"groups": ["tei"]
				},
				"requestBody": {
					"description": "Status of work to be applied in metadata",
					"content": {
						"application/json": {
							"schema": {
								"type": "array",
								"items": {
									"type": "object",
									"properties": {
										"context": {
											"type": "string"
										},
										"start": {
											"type": "number"
										},
										"end": {
											"type": "number"
										},
										"type": {
											"type": "string"
										},
										"text": {
											"type": "string"
										},
										"properties": {
											"type": "object"
										}
									}
								}
							}
						}
					}
				},
				"parameters": [
					{
						"name": "path",
						"in": "path",
						"description": "Relative path to the TEI document to be changed",
						"schema": {
							"type": "string",
							"example": "annotate/bach_test2.xml"
						},
						"required": true
					},
					{
						"name": "status",
						"in": "query",
						"description": "Status of the document.",
						"schema": {
							"type": "string"
						}
					}
				],
				"responses": {
					"200": {
						"description": "Returns the merged TEI XML",
						"content": {
							"application/json": {
								"schema": {
									"type": "object"
								}
							}
						}
					}
				}
			}
    	},	
		
    	"/api/status/meta/{path}": {
			"get": {
				"summary": "Returns some metadata about the document",
				"tags": ["status"],
				"operationId": "custom:status-metadata",
				"parameters": [
					{
						"name": "path",
						"in": "path",
						"required": true,
						"schema": {
							"type": "string",
							"example": "annotate/bach_test2.xml"
						}
					}
				],
				"responses": {
					"200": {
						"description": "Metadata about the document as JSON object",
						"content": {
							"application/json": {
								"schema": {
									"type": "object"
								}
							}
						}
					},
					"404": {
						"description": "Document not found",
						"content": {
							"application/json": {
								"schema": {
									"type": "object"
								}
							}
						}
					}
				}
			}
		}
	},
    "security": [
        {
            "cookieAuth": []
        },
        {
            "basicAuth": []
        }
    ]
}