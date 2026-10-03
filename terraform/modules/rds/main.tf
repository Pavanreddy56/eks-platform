# PostgreSQL on Amazon RDS in isolated database subnets.
# Credentials are generated here and stored in AWS Secrets Manager, where the
# External Secrets Operator reads them and creates a Kubernetes Secret.

resource "random_password" "master" {
  length  = 32
  special = true
  # RDS forbids '/', '@', '"' and spaces in the master password.
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  description = "PostgreSQL access for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-db" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  count = length(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from EKS nodes and pods"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-pg-"
  family      = "postgres${var.engine_major_version}"
  description = "Parameter group for ${var.name}"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # log queries slower than 1s
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "this" {
  #checkov:skip=CKV_AWS_157:Multi-AZ is disabled in dev to control cost (enable via var.multi_az)
  #checkov:skip=CKV_AWS_118:Enhanced monitoring is out of scope for the dev environment
  #checkov:skip=CKV_AWS_353:Performance Insights is not needed for the dev environment
  #checkov:skip=CKV_AWS_293:Deletion protection is off in dev so the stack can be torn down (var.deletion_protection)
  #checkov:skip=CKV2_AWS_60:Copy-tags-to-snapshot is enabled; check misfires on variables
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_major_version
  instance_class = var.instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.username
  password = random_password.master.result
  port     = 5432

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  multi_az               = var.multi_az

  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  enabled_cloudwatch_logs_exports     = ["postgresql", "upgrade"]

  backup_retention_period   = 7
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final"

  tags = var.tags
}

resource "aws_secretsmanager_secret" "db" {
  #checkov:skip=CKV_AWS_149:AWS-managed key is sufficient for this demo
  #checkov:skip=CKV2_AWS_57:Automatic rotation is a documented next step (needs a rotation Lambda)
  name                    = var.secret_name
  description             = "Connection details for ${var.name} PostgreSQL"
  recovery_window_in_days = var.secret_recovery_window_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.master.result
    host     = aws_db_instance.this.address
    port     = tostring(aws_db_instance.this.port)
    dbname   = var.db_name
  })
}
