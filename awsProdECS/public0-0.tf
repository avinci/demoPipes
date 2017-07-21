# ========================ECS Instances=======================
resource "aws_instance" "prodECSIns" {
  depends_on = [
    "aws_ecs_cluster.prod-aws"]

  count = 3

  # ami = "${var.ecsAmi}"
  ami = "${lookup(var.ecsAmi, var.region)}"
  availability_zone = "${lookup(var.availability_zone, var.region)}"
  instance_type = "t2.micro"
  key_name = "${var.aws_key_name}"
  subnet_id = "${var.prod_public_sn_id}"
  iam_instance_profile = "demoECSInstProf"
  associate_public_ip_address = true
  source_dest_check = false
  user_data = "#!/bin/bash \n echo ECS_CLUSTER=${aws_ecs_cluster.prod-aws.name} >> /etc/ecs/ecs.config"

  security_groups = [
    "${var.prod_public_sg_id}"]

  tags = {
    Name = "prodECSIns${count.index}"
  }
}
