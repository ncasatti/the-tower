function swagger-serve
    if test (count $argv) -eq 0
        echo "usage: swagger-serve <path/to/openapi.yaml>"
        return 1
    end

    set spec_file (realpath $argv[1])

    if not test -f $spec_file
        echo "error: file not found: $spec_file"
        return 1
    end

    set spec_dir (dirname $spec_file)
    set spec_name (basename $spec_file)

    echo "Swagger UI → http://localhost:8081"
    docker run --rm -p 8081:8080 \
        -e SWAGGER_JSON=/spec/$spec_name \
        -v $spec_dir:/spec \
        swaggerapi/swagger-ui
end
