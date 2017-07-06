output "test_ecs_ins_0_ip" {
  value = "${aws_instance.testECSIns.0.id}"
}

output "test_ecs_ins_1_ip" {
  value = "${aws_instance.testECSIns.1.id}"
}

