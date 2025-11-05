#!/usr/bin/env python3
"""
Test if IAM account can access RDS database
"""
import boto3
import sys
from botocore.exceptions import ClientError
from app.config import settings

def test_iam_rds_access():
    """Test if IAM credentials can see/access RDS"""
    print("🔐 Testing IAM Account Access to RDS\n")
    
    # Check IAM credentials
    if not settings.aws_access_key_id or not settings.aws_secret_access_key:
        print("❌ AWS credentials not configured in .env")
        return False
    
    print(f"✅ AWS Credentials Found")
    print(f"   Access Key ID: {settings.aws_access_key_id}")
    print(f"   Region: {settings.aws_region}\n")
    
    try:
        # Create RDS client
        print("1️⃣ Connecting to AWS RDS service...")
        rds_client = boto3.client(
            'rds',
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_region
        )
        
        # Try to describe RDS instances
        print("2️⃣ Attempting to list RDS instances...")
        try:
            response = rds_client.describe_db_instances()
            
            print(f"   ✅ SUCCESS! IAM account can access RDS\n")
            print(f"   Found {len(response.get('DBInstances', []))} RDS instance(s):\n")
            
            for db_instance in response.get('DBInstances', []):
                db_id = db_instance.get('DBInstanceIdentifier', 'N/A')
                engine = db_instance.get('Engine', 'N/A')
                status = db_instance.get('DBInstanceStatus', 'N/A')
                endpoint = db_instance.get('Endpoint', {})
                endpoint_address = endpoint.get('Address', 'N/A') if endpoint else 'N/A'
                endpoint_port = endpoint.get('Port', 'N/A') if endpoint else 'N/A'
                
                print(f"   📊 Instance: {db_id}")
                print(f"      Engine: {engine}")
                print(f"      Status: {status}")
                print(f"      Endpoint: {endpoint_address}:{endpoint_port}")
                
                # Check if this matches our configured RDS
                if endpoint_address == settings.rds_host:
                    print(f"      ✅ This matches our configured RDS host!\n")
                else:
                    print()
            
            # Check specific instance if we have the identifier
            if settings.rds_host:
                host_parts = settings.rds_host.split('.')
                if len(host_parts) > 0:
                    # Extract DB instance identifier from hostname
                    # Format: identifier.xxxxx.region.rds.amazonaws.com
                    potential_id = host_parts[0]
                    
                    print(f"3️⃣ Checking specific instance: {potential_id}...")
                    try:
                        instance_response = rds_client.describe_db_instances(
                            DBInstanceIdentifier=potential_id
                        )
                        instance = instance_response['DBInstances'][0]
                        
                        print(f"   ✅ Instance found!")
                        print(f"      Name: {instance.get('DBInstanceIdentifier')}")
                        print(f"      Engine: {instance.get('Engine')} {instance.get('EngineVersion')}")
                        print(f"      Instance Class: {instance.get('DBInstanceClass')}")
                        print(f"      Storage: {instance.get('AllocatedStorage')} GB")
                        print(f"      Public Access: {instance.get('PubliclyAccessible', False)}")
                        print(f"      Multi-AZ: {instance.get('MultiAZ', False)}")
                        print(f"      Status: {instance.get('DBInstanceStatus')}\n")
                        
                        # Check security groups
                        vpc_security_groups = instance.get('VpcSecurityGroups', [])
                        if vpc_security_groups:
                            print(f"   🔒 Security Groups:")
                            for sg in vpc_security_groups:
                                print(f"      - {sg.get('VpcSecurityGroupId')} ({sg.get('Status')})")
                            print()
                        
                    except ClientError as e:
                        if e.response['Error']['Code'] == 'DBInstanceNotFound':
                            print(f"   ⚠️  Instance '{potential_id}' not found (might use different identifier)")
                        else:
                            raise
            
            return True
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_msg = e.response['Error']['Message']
            
            print(f"   ❌ Access Denied: {error_code}")
            print(f"      {error_msg}\n")
            
            if error_code == 'AccessDenied':
                print("   💡 Your IAM account needs these permissions:")
                print("      - rds:DescribeDBInstances")
                print("      - rds:DescribeDBInstance")
                print("   Update your IAM policy to include these permissions.")
            elif error_code == 'InvalidClientTokenId':
                print("   💡 Check your AWS credentials in .env")
            
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_iam_rds_access()
    sys.exit(0 if success else 1)

