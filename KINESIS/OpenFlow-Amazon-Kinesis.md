What we need to do:

  1. Choose a Kinesis connector variant -- since this is a demo, I'd suggest starting with kinesis (the
  standard one)
  2. Set up External Access Integration (EAI) -- since this is SPCS, the runtime needs network access to
  reach AWS Kinesis endpoints
  3. Collect your AWS details -- Kinesis stream name, region, AWS credentials
  4. Deploy and configure the connector

   Task: Deploy Amazon Kinesis connector demo on AWS AU account (0/6 steps) (ctrl+d to open tasks)
     Create AWS Kinesis stream in ap-southeast-2
     Set up EAI for Kinesis network access (SPCS)
     Deploy kinesis connector from registry
     Inspect and configure connector parameters
     Verify controllers and enable
     Start connector and validate data flow


1. Install AWS CLI:
    brew install awscli 2>&1

2. 