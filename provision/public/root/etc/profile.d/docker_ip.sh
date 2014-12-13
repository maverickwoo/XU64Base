docker_ip ()
{
  docker inspect -f "{{ .NetworkSettings.IPAddress }}" $1
}
