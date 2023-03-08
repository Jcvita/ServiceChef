SUBNET_DIR='subnets/'

def main():
    # create 254 yaml files for each subnet starting at 10.0.1.0/24 and ending at 10.0.254.0/24
    # each yaml file will be titled with the number in the 3rd octet of the subnet
    # each yaml file will contain:
    # subnet_cidr: <subnet cidr>
    for i in range(1, 255):
        subnet = '10.0.' + str(i) + '.0/24'
        filename = str(i) + '.yaml'
        with open("../" + SUBNET_DIR + filename, 'w') as f:
            f.write('subnet_cidr: ' + subnet)
            f.close()

if __name__ == '__main__':
    main()