# ADR-0008: VPC design with single NAT Gateway and three Availability Zones

## Status

Accepted.

## Context

The VPC is the network foundation every other module sits on. The design decisions made here are not easily reversible once workloads are running, so they need to be intentional. The relevant questions:

1. How many Availability Zones should subnets span?
2. Should public and private subnets be split, and how should traffic flow between them and the internet?
3. How many NAT Gateways are needed?
4. What CIDR layout makes sense for the subnet count?

## Decision

Use three Availability Zones (eu-west-1a, eu-west-1b, eu-west-1c) with both a public and private subnet in each, for a total of six subnets. Use a single shared NAT Gateway in one public subnet for all private-subnet outbound traffic. Allocate `10.0.0.0/16` as the VPC CIDR, with each subnet getting a `/20` block (4096 addresses).

## Consequences

**Benefits of three AZs:**

- EKS managed node groups distribute nodes across AZs automatically, so a single-AZ outage does not bring down the cluster.
- Load balancers can target subnets in all three AZs for the same fault tolerance.
- The 3-AZ pattern is the standard production minimum and matches what an interviewer would expect to see.

**Benefits of public/private split:**

- Workloads (EKS nodes, future RDS, future ElastiCache) live in private subnets and cannot be reached from the internet directly. Defense in depth.
- Load balancers and NAT live in public subnets, exposed only by deliberate design.
- The split is enforced by route table associations, not by hope or convention.

**Benefits and costs of single NAT Gateway:**

- One NAT costs roughly $0.045 per hour. Three NATs (one per AZ for high availability) would triple this to $0.135 per hour, or about $97 per month on top of data transfer.
- A single NAT means private-subnet workloads in AZ-b and AZ-c send outbound traffic through AZ-a, incurring cross-AZ data transfer charges and creating a single point of failure for outbound internet access.
- For a portfolio dev project with no SLA, the cost saving is the right tradeoff. The production answer would be one NAT per AZ.
- This is documented explicitly as an input variable (`single_nat_gateway`), so flipping to multi-AZ NAT in production is a one-line change rather than a refactor.

**CIDR layout:**

- `10.0.0.0/16` gives 65,536 addresses, which is more than enough headroom for any realistic dev workload while still being a "small" private CIDR.
- Six `/20` subnets (each 4,094 usable addresses) is overkill for current needs but matches what would be reasonable in production. Sizing subnets too small causes painful migrations later; sizing them generously costs nothing.
