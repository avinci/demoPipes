output "prod_ecs_ins_0_ip" {
  value = "${aws_instance.prodECSIns.0.public_ip}"
}

output "prod_ecs_ins_1_ip" {
  value = "${aws_instance.prodECSIns.1.public_ip}"
}

output "prod_ecs_ins_2_ip" {
  value = "${aws_instance.prodECSIns.2.public_ip}"
}

output "prod_ecs_cluster_id" {
  value = "${aws_ecs_cluster.prod-aws.id}"
}
