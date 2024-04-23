# Step 6, 7 - Generates test traffic to the load balancer to show effectiveness and autoscaling
#!/bin/bash

# Prompt user to enter the DNS name of the load balancer
read -p "Enter the DNS name of the load balancer: " LB_DNS_NAME

# Loop to send requests with different URLs, supressing output
for i in {1..100}; do
    curl -s "http://$LB_DNS_NAME/$i" > /dev/null &
done

# Wait for all requests to finish
wait

echo "Test traffic generation complete."
