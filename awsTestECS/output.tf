output "test_ecs_ins_0_ip" {
  value = "${aws_instance.testECSIns.0.public_ip}"
}

output "test_ecs_ins_1_ip" {
  value = "${aws_instance.testECSIns.1.public_ip}"
}

output "test_ecs_cluster_id" {
  value = "${aws_ecs_cluster.test-aws.id}"
}
