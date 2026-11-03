# ================================================
# VPC：学習環境専用の仮想ネットワーク
# ================================================
# AWSリソースを同じネットワーク境界へまとめ、SubnetやSecurity Groupの所属先にする。
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Public Subnet：ALBを配置するAZ1のSubnet。経路の設定によってPublicとして機能する。
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-az1"
  }
}

# Public Subnet：ALBを複数AZへ配置できるよう、AZ2にも用意する。
resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-az2"
  }
}

# Private Subnet：インターネットから直接到達させないアプリ・DB用Subnet。
resource "aws_subnet" "private_az1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-az1"
  }
}

# Private Subnet：複数AZにアプリ・DB用Subnetを用意し、配置先の選択肢を確保する。
resource "aws_subnet" "private_az2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.21.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-az2"
  }
}

# 利用可能AZのデータ参照：リージョンで利用できるAZ名を取得しSubnetへ割り当てる。
data "aws_availability_zones" "available" {
  state = "available"
}

# Internet Gateway：Public Subnetの通信をインターネットへ接続する出口。
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Public Route Table：Public Subnetに適用する通信経路をまとめる。
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-public-route-table"
  }
}

# Public Default Route：宛先を限定しない通信をInternet Gatewayへ送る。
resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Public Subnet Association：AZ1のPublic SubnetにPublic Route Tableを適用する。
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

# Public Subnet Association：AZ2のPublic Subnetにも同じ経路を適用する。
resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table：Private Subnet用の経路を分離し、Public側と異なる出口を設定する。
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-private-route-table"
  }
}

# Private Subnet Association：AZ1のPrivate SubnetにPrivate Route Tableを適用する。
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

# Private Subnet Association：AZ2のPrivate Subnetにも同じ経路を適用する。
resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private.id
}

# ================================================
# NAT Gateway用 Elastic IP
# ================================================
# NAT Gatewayのインターネット側アドレスとして使う固定IPv4アドレスを確保する。

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }
}

# ================================================
# NAT Gateway
# ================================================
# Private Subnetから外向き通信を行うための中継点。受信方向の直接接続には使わない。

resource "aws_nat_gateway" "main" {
  allocation_id     = aws_eip.nat.id
  connectivity_type = "public"
  subnet_id         = aws_subnet.public_az2.id

  # Internet Gatewayの準備後にNAT Gatewayを作成する
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gateway"
  }
}

# ================================================
# Private Route Tableのデフォルトルート
# ================================================
# Private Subnetからインターネット向けの通信をNAT Gateway経由にする。

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
