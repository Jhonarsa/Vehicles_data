create database if not exists vehicule_data;
use vehicule_data;

-- table cities
create table if not exists cities (
    city_id int primary key,
    city_name varchar(255) not null
);

-- table brands
create table if not exists brands (
    brand_id int primary key,
    brand_name varchar(255) not null
);

-- table body types
create table if not exists body_types (
    body_type_id int primary key,
    body_type varchar(255) not null
);

-- table lines
create table if not exists lines_name (
    line_id int primary key,
    brand_id int not null,
    line_name varchar(100) not null,
    foreign key (brand_id) references brands(brand_id)
);

-- table service
create table if not exists service_mode (
    service_mode_id int primary key,
    service_mode varchar(255) not null
);

-- table class
create table if not exists vehicle_classes (
    vehicle_class_id int primary key,
    vehicle_class varchar(255) not null
);

-- table status
create table if not exists vehicle_statuses (
    vehicle_status_id int primary key,
    vehicle_status varchar(255) not null
);

-- table versions
CREATE TABLE if not exists versions (
    version_id INT PRIMARY KEY,
    line_id INT NOT NULL,
    version_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (line_id) REFERENCES lines_name(line_id)
);

-- creación de la tabla actuaciones (relación muchos a muchos entre actores y series)
create table vehicles (
    vehicle_id int primary key,
    brand_id int not null,
    line_id int not null,
    version_id int not null,
    vehicle_class_id int not null,
    body_type_id int not null,
    registration_date date not null,
    plate_number varchar(20) not null,
    vehicle_status_id int not null,
    service_mode_id int not null,
    city_id int not null,
    model_year int not null,
    engine_displacement_cc int not null,
    num_doors int not null,
    foreign key (brand_id) references brands(brand_id),
    foreign key (line_id) references lines_name(line_id),
    foreign key (version_id) references versions(version_id),
    foreign key (vehicle_class_id) references vehicle_classes(vehicle_class_id),
    foreign key (body_type_id) references body_types(body_type_id),
    foreign key (vehicle_status_id) references vehicle_statuses(vehicle_status_id),
    foreign key (service_mode_id) references service_mode(service_mode_id),
    foreign key (city_id) references cities(city_id)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cities.csv'
INTO TABLE cities
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load data into the 'brands' table from CSV
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/brands.csv'
INTO TABLE brands
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load data into the 'body_types' table from CSV
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/body_types.csv'
INTO TABLE body_types
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load data into the 'lines' table from CSV
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/service_modes.csv'
INTO TABLE service_mode
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/vehicle_classes.csv'
INTO TABLE vehicle_classes
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load data into the 'lines' table from CSV
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/lines.csv'
INTO TABLE lines_name
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/versions.csv'
INTO TABLE versions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/vehicle_statuses.csv'
INTO TABLE vehicle_statuses
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Load data into the 'vehicles' table from CSV
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/vehicles.csv'
INTO TABLE vehicles
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;