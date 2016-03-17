# source docker helpers
. util/docker.sh

@test "Start Container" {
  start_container "test-single" "192.168.0.2"
}

@test "Configure" {
  # Run Hook
  run run_hook "test-single" "configure" "$(payload configure)"
  [ "$status" -eq 0 ]

  # Verify hoarder configuration
  run docker exec test-single bash -c "[ -f /etc/hoarder/config.yml ]"
  [ "$status" -eq 0 ]

  # Verify narc configuration
  run docker exec test-single bash -c "[ -f /opt/gonano/etc/narc.conf ]"
  [ "$status" -eq 0 ]
}

@test "Start" {
  # Run hook
  run run_hook "test-single" "start" "{}"
  [ "$status" -eq 0 ]

  # Verify hoarder running
  run docker exec test-single bash -c "ps aux | grep [h]oarder"
  [ "$status" -eq 0 ]

  # Verify narc running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 0 ]
}

@test "Verify Service" {
  # Verify blob list is empty
  run docker exec test-single bash -c "curl -H \"x-auth-token: 123\" http://localhost:7410/blobs 2> /dev/null"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]

  # Add a blob
  run docker exec test-single bash -c "curl -H \"x-auth-token: 123\" http://localhost:7410/blobs/test -d \"data\" 2> /dev/null "
  echo "$output"
  [ "$status" -eq 0 ]

  # Verify blob exists
  run docker exec test-single bash -c "curl -H \"x-auth-token: 123\" http://localhost:7410/blobs/test 2> /dev/null"
  echo "$output"
  [ "$status" -eq 0 ]
  [ "$output" = "data" ]
}

@test "Stop" {
  # Run hook
  run run_hook "test-single" "stop" "{}"
  [ "$status" -eq 0 ]

  # Wait until services shut down
  while docker exec "test-single" bash -c "ps aux | grep [h]oarder"
  do
    sleep 1
  done

  # Verify hoarder is not running
  run docker exec test-single bash -c "ps aux | grep [h]oarder"
  [ "$status" -eq 1 ]

  # Verify narc is not running
  run docker exec test-single bash -c "ps aux | grep [n]arc"
  [ "$status" -eq 1 ]
}

@test "Stop Container" {
  stop_container "test-single"
}
