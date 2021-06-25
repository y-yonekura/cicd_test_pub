resource "random_pet" "pet" {
	keepers = {
		val = timestamp()
	}
}

output "pet" {
	value = random_pet.pet.id
}


variable "test_map_var" {
	type = map
	default = {
		key_1 : "default_value_123",
		key_2 : "default_value_456"
	}
}

variable "test_str_var" {
	type = string
	default = "default_str_value123456789"
}

output "output_map_key1" {
  value = "${lookup(var.test_map_var , "key_1")}"
}

output "output_map_key2" {
  value = "${lookup(var.test_map_var , "key_2")}"
}

output "output_str_var" {
  value = "${var.test_str_var}"
}
