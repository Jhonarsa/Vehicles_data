-- data validation and cleaning process

-- step 1: validate referential integrity
select vehicle_id from vehicles where brand_id not in (select brand_id from brands);
select vehicle_id from vehicles where line_id not in (select line_id from lines_name);
select vehicle_id from vehicles where version_id not in (select version_id from versions);
select vehicle_id from vehicles where vehicle_class_id not in (select vehicle_class_id from vehicle_classes);
select vehicle_id from vehicles where body_type_id not in (select body_type_id from body_types);
select vehicle_id from vehicles where vehicle_status_id not in (select vehicle_status_id from vehicle_statuses);
select vehicle_id from vehicles where service_mode_id not in (select service_mode_id from service_mode);
select vehicle_id from vehicles where city_id not in (select city_id from cities);

-- step 2: univariate validation

-- check date ranges and model years
select min(registration_date) as min_reg_date,
       max(registration_date) as max_reg_date,
       min(model_year) as min_year,
       max(model_year) as max_year
from vehicles;
 

-- check plate number length
select min(length(plate_number)) as min_len,
       max(length(plate_number)) as max_len
from vehicles;

 
-- step 3: bivariate validation

-- engine displacement by vehicle class
select b.vehicle_class, min(a.engine_displacement_cc) as min_cc,
       max(a.engine_displacement_cc) as max_cc
from vehicles a
left join vehicle_classes b on a.vehicle_class_id = b.vehicle_class_id
group by b.vehicle_class;

-- number of doors by vehicle class
select b.vehicle_class, min(a.num_doors) as min_doors,
       max(a.num_doors) as max_doors
from vehicles a
left join vehicle_classes b on a.vehicle_class_id = b.vehicle_class_id
group by b.vehicle_class;

-- step 4: create a working copy of the dataset
create table vehicles_clean like vehicles;
insert into vehicles_clean select * from vehicles;

-- verify copy
select count(*) as original_count from vehicles;
select count(*) as clean_count from vehicles_clean;

-- step 5: correct plate number format
set sql_safe_updates = 0;

select plate_number
from vehicles_clean
where length(plate_number) > 5;

update vehicles_clean
set plate_number = upper(
    regexp_replace(
        replace(trim(plate_number), ' ', ''),
        '[^a-z0-9]', ''
    )
);
 
-- verify plate number changes
select vehicle_class, min(length(plate_number)) as min_len,
       max(length(plate_number)) as max_len
from vehicles_clean a
left join vehicle_classes b on a.vehicle_class_id = b.vehicle_class_id
group by vehicle_class;

/***********************************************************************
 Step 6: Correct number of doors
 ------------------------------------------------------------------------
 🎯 Objective:
 - Standardize the variable `num_doors` according to vehicle type.

 🛠️ Problem:
 - Motorcycles were assigned doors, which is invalid.
 - Cars and pickups had values outside the valid range [2–5].
 - Trucks had values outside the valid range [1–4].
 - Some vehicles had missing or extreme values without a mode.

 ✅ Solution / Approach:
 - Motorcycles: assign 0 doors.
 - Cars and pickups:
     - If outside the range, assign the mode of 
       (brand, line, version, body_type).
     - If mode does not exist, fallback to mode of 
       (vehicle_class, body_type).
     - If still missing, fallback to mode of vehicle_class.
 - Trucks: same logic, but valid range [1–4].

************************************************************************/
update vehicles_clean vc
join vehicle_classes c 
    on vc.vehicle_class_id = c.vehicle_class_id

-- detailed mode: brand + line + version + body_type (only valid ranges per class)
left join (
    select brand_id, line_id, version_id, body_type_id,
           cast(
             substring_index(
               group_concat(cast(num_doors as char) order by cnt desc, num_doors asc),
               ',', 1
             ) as unsigned
           ) as mode_doors
    from (
        select vc2.brand_id, vc2.line_id, vc2.version_id, vc2.body_type_id, vc2.num_doors,
               count(*) as cnt
        from vehicles_clean vc2
        join vehicle_classes cc 
          on vc2.vehicle_class_id = cc.vehicle_class_id
        where (
                (lower(cc.vehicle_class) in ('car', 'pickup') and vc2.num_doors between 2 and 5)
             or (lower(cc.vehicle_class) = 'truck' and vc2.num_doors between 1 and 4)
              )
        group by vc2.brand_id, vc2.line_id, vc2.version_id, vc2.body_type_id, vc2.num_doors
    ) t
    group by brand_id, line_id, version_id, body_type_id
) modes_specific
  on vc.brand_id = modes_specific.brand_id
 and vc.line_id = modes_specific.line_id
 and vc.version_id = modes_specific.version_id
 and vc.body_type_id = modes_specific.body_type_id

-- fallback mode: vehicle_class + body_type (only valid ranges per class)
left join (
    select vehicle_class_id, body_type_id,
           cast(
             substring_index(
               group_concat(cast(num_doors as char) order by cnt desc, num_doors asc),
               ',', 1
             ) as unsigned
           ) as mode_doors_body
    from (
        select cc.vehicle_class_id, vc3.body_type_id, vc3.num_doors,
               count(*) as cnt
        from vehicles_clean vc3
        join vehicle_classes cc 
          on vc3.vehicle_class_id = cc.vehicle_class_id
        where (
                (lower(cc.vehicle_class) in ('car', 'pickup') and vc3.num_doors between 2 and 5)
             or (lower(cc.vehicle_class) = 'truck' and vc3.num_doors between 1 and 4)
              )
        group by cc.vehicle_class_id, vc3.body_type_id, vc3.num_doors
    ) u
    group by vehicle_class_id, body_type_id
) modes_body
  on vc.vehicle_class_id = modes_body.vehicle_class_id
 and vc.body_type_id = modes_body.body_type_id

-- fallback mode: vehicle_class only (only valid ranges per class)
left join (
    select vehicle_class_id,
           cast(
             substring_index(
               group_concat(cast(num_doors as char) order by cnt desc, num_doors asc),
               ',', 1
             ) as unsigned
           ) as mode_doors_class
    from (
        select cc.vehicle_class_id, vc4.num_doors,
               count(*) as cnt
        from vehicles_clean vc4
        join vehicle_classes cc 
          on vc4.vehicle_class_id = cc.vehicle_class_id
        where (
                (lower(cc.vehicle_class) in ('car', 'pickup') and vc4.num_doors between 2 and 5)
             or (lower(cc.vehicle_class) = 'truck' and vc4.num_doors between 1 and 4)
              )
        group by cc.vehicle_class_id, vc4.num_doors
    ) v
    group by vehicle_class_id
) modes_class
  on vc.vehicle_class_id = modes_class.vehicle_class_id

set vc.num_doors = case
    -- motorcycles must be 0 doors
    when lower(c.vehicle_class) = 'motorcycle' then 0

    -- cars and pickups: enforce 2..5; fill nulls/out-of-range with fallback modes
    when lower(c.vehicle_class) in ('car', 'pickup')
         and (vc.num_doors is null or vc.num_doors < 2 or vc.num_doors > 5)
    then coalesce(modes_specific.mode_doors, modes_body.mode_doors_body, modes_class.mode_doors_class)

    -- trucks: enforce 1..4; fill nulls/out-of-range with fallback modes
    when lower(c.vehicle_class) = 'truck'
         and (vc.num_doors is null or vc.num_doors < 1 or vc.num_doors > 4)
    then coalesce(modes_specific.mode_doors, modes_body.mode_doors_body, modes_class.mode_doors_class)

    -- otherwise keep the original value
    else vc.num_doors
end;

-- verify num_doors changes
select b.vehicle_class, min(a.num_doors) as min_doors,
       max(a.num_doors) as max_doors
from vehicles_clean a
left join vehicle_classes b on a.vehicle_class_id = b.vehicle_class_id
group by b.vehicle_class;

/***********************************************************************
 Step 7: Correct engine displacement (engine_displacement_cc)
 ------------------------------------------------------------------------
 🎯 Objective:
 - Ensure that engine displacement values are realistic for each vehicle class.

 🛠️ Problem:
 - Some motorcycles had unrealistically high displacements (1000–3000 cc).
 - Some cars, pickups, and trucks had unrealistically small displacements (50–300 cc).

 ✅ Solution / Approach:
 - Define a valid range per vehicle class.
 - Identify the most typical engine displacement per (class, brand, line).
 - If a value is outside the range:
     - Replace it with the typical displacement of that brand/line/class.
 - For motorcycles: if the typical displacement is within [80–800], 
   narrow the range to [80–800] to enforce stricter validation.

************************************************************************/

SELECT c.vehicle_class, b.brand_name, l.line_name, vc.engine_displacement_cc,
    COUNT(*) AS num_records,
    ROUND((COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY c.vehicle_class, b.brand_name, l.line_name
        )) * 100, 2) AS pct_in_group
FROM vehicles_clean vc
JOIN brands b ON vc.brand_id = b.brand_id
JOIN lines_name l ON vc.line_id = l.line_id
JOIN vehicle_classes c ON vc.vehicle_class_id = c.vehicle_class_id
GROUP BY c.vehicle_class, b.brand_name, l.line_name, vc.engine_displacement_cc
ORDER BY c.vehicle_class, b.brand_name, l.line_name, num_records DESC;

-- create a cte to find the most typical engine displacement per class, brand, and line
with typical_engine as (
    select c.vehicle_class, b.brand_name, l.line_name, vc.engine_displacement_cc,
        count(*) as num_records, row_number() over (
            partition by c.vehicle_class, b.brand_name, l.line_name order by count(*) desc
        ) as rn
    from vehicles_clean vc
    join brands b on vc.brand_id = b.brand_id
    join lines_name l on vc.line_id = l.line_id
    join vehicle_classes c on vc.vehicle_class_id = c.vehicle_class_id
    group by c.vehicle_class, b.brand_name, l.line_name, vc.engine_displacement_cc),

-- Define the typical range for each vehicle class
class_ranges as (select 'car' as vehicle_class, 800 as min_cc, 3000 as max_cc
    union all select 'pickup', 2000, 5000
    union all select 'truck', 4000, 15000
    union all select 'motorcycle', 80, 1500
),

-- Adjust motorcycle logic so if the typical engine is inside 80–800, 
-- Use that narrower range to replace out-of-range engines
adjusted_ranges as (
    select r.vehicle_class,
        case when r.vehicle_class = 'motorcycle' and te.engine_displacement_cc between 80 and 800 then 80 
		else r.min_cc end as min_cc,
        case when r.vehicle_class = 'motorcycle' and te.engine_displacement_cc between 80 and 800 then 800
		else r.max_cc end as max_cc,
        te.brand_name, te.line_name, te.engine_displacement_cc as typical_engine
    from class_ranges r
    left join typical_engine te on r.vehicle_class = te.vehicle_class and te.rn = 1)

-- Update vehicles outside their adjusted range with the typical engine displacement
update vehicles_clean vc
join brands b on vc.brand_id = b.brand_id
join lines_name l  on vc.line_id = l.line_id
join vehicle_classes c on vc.vehicle_class_id = c.vehicle_class_id
join adjusted_ranges ar on c.vehicle_class = ar.vehicle_class
    and b.brand_name = ar.brand_name and l.line_name = ar.line_name
set vc.engine_displacement_cc = ar.typical_engine
where vc.engine_displacement_cc < ar.min_cc or vc.engine_displacement_cc > ar.max_cc;

/***********************************************************************
 Step 8: Correct model year (model_year)
 ------------------------------------------------------------------------
 🎯 Objective:
 - Ensure consistency between `model_year` and `registration_date`.

 🛠️ Problem:
 - Some records had a `model_year` earlier than (registration_year - 2).
 - Some had a `model_year` later than (registration_year + 2).
 - Some even had model_year > current_year + 1.

 ✅ Solution / Approach:
 - Build valid ranges per (vehicle_class, brand, line, version) 
   based only on records where `model_year = registration_year`.
 - If `model_year` differs significantly from registration_year:
     - Replace with registration_year if it falls within the valid range.
 - Additional rule: if model_year > current_year + 1, 
   always replace with registration_year.

************************************************************************/

with year_ranges as (
    select
        vc.vehicle_class_id,
        v.brand_id,
        v.line_id,
        v.version_id,
        min(v.model_year) as min_year,
        max(v.model_year) as max_year
    from vehicles v
    join vehicle_classes vc 
        on v.vehicle_class_id = vc.vehicle_class_id
    where v.model_year = year(v.registration_date)
    group by
        vc.vehicle_class_id,
        v.brand_id,
        v.line_id,
        v.version_id
)
-- Update model_year when the difference with registration_date year is more than 2 years
update vehicles_clean v
join year_ranges yr 
    on v.vehicle_class_id = yr.vehicle_class_id
    and v.brand_id = yr.brand_id
    and v.line_id = yr.line_id
    and v.version_id = yr.version_id
set v.model_year = year(v.registration_date)
where (abs(v.model_year - year(v.registration_date)) > 2
  or v.model_year > year(curdate()) + 1)
  and year(v.registration_date) between yr.min_year and yr.max_year;

select min(registration_date) as min_reg_date,
       max(registration_date) as max_reg_date,
       min(model_year) as min_year,
       max(model_year) as max_year
from vehicles_clean;

