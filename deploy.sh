docker buildx build --platform linux/amd64 -t ngocxxu/vocab-be:latest .

docker push ngocxxu/vocab-be:latest

kubectl rollout restart deployment/vocab-be -n vocab-be