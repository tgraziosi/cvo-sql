SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE procedure [dbo].[imInvTabSum_sp]
as

create table #t1
(
    record_type         varchar(64),
    batch               int,
    count_type          varchar(64),
    reccount            int)

insert into #t1
select 'Inventory Master Records',batch_no,'Not Validated or Validation Errors',count(*)
from iminvmast_mstr_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no

/*
insert into #t1
select 'Inventory Master Records','Validation Errors',count(*)
from iminvmast_mstr_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no
*/

insert into #t1
select 'Inventory Master Records',batch_no,'Validated / Not Processed',count(*)
from iminvmast_mstr_vw
where record_status_1 = 0
and record_status_2 = 0
group by batch_no


insert into #t1
select 'Inventory Master Records',batch_no,'Processed',count(*)
from iminvmast_mstr_vw where process_status = 1
group by batch_no

insert into #t1
select 'Inventory Master Records',batch_no,'Total',count(*)
from iminvmast_mstr_vw
group by batch_no

/********/
insert into #t1
select 'Inventory BOM Records',batch_no,'Not Validated or Validation Errors',count(*)
from iminvmast_bom_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no

/*
insert into #t1
select 'Inventory BOM Records','Validation Errors',count(*)
from iminvmast_bom_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no
*/

insert into #t1
select 'Inventory BOM Records',batch_no,'Validated / Not Processed',count(*)
from iminvmast_bom_vw
where record_status_1 = 0
and record_status_2 = 0
group by batch_no


insert into #t1
select 'Inventory BOM Records',batch_no,'Processed',count(*)
from iminvmast_bom_vw
where process_status = 1
group by batch_no

insert into #t1
select 'Inventory BOM Records',batch_no,'Total',count(*)
from iminvmast_bom_vw
group by batch_no

/********/
insert into #t1
select 'Inventory Lot/Bin/Serial Inv Qty Records',batch_no,'Not Validated or Validation Errors',count(*)
from iminvmast_lbs_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no

/*
insert into #t1
select 'Inventory Lot/Bin/Serial Inv Qty Records',batch_no,'Validation Errors',count(*)
from iminvmast_lbs_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no
*/

insert into #t1
select 'Inventory Lot/Bin/Serial Inv Qty Records',batch_no,'Validated / Not Processed',count(*)
from iminvmast_lbs_vw
where record_status_1 = 0
and record_status_2 = 0
group by batch_no

insert into #t1
select 'Inventory Lot/Bin/Serial Inv Qty Records',batch_no,'Processed',count(*)
from iminvmast_lbs_vw
where process_status = 1
group by batch_no

insert into #t1
select 'Inventory Lot/Bin/Serial Inv Qty Records',batch_no,'Total',count(*)
from iminvmast_lbs_vw
group by batch_no

/********/
insert into #t1
select 'Inventory Location Records',batch_no,'Not Validated or Validation Errors',count(*)
from iminvmast_loc_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no

/*
insert into #t1
select 'Inventory Location Records','Validation Errors',count(*)
from iminvmast_loc_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no
*/

insert into #t1
select 'Inventory Location Records',batch_no,'Validated / Not Processed',count(*)
from iminvmast_loc_vw
where record_status_1 = 0
and record_status_2 = 0
group by batch_no

insert into #t1
select 'Inventory Location Records',batch_no,'Processed',count(*)
from iminvmast_loc_vw
where process_status = 1
group by batch_no

insert into #t1
select 'Inventory Location Records',batch_no,'Total',count(*)
from iminvmast_loc_vw
group by batch_no

/********/
insert into #t1
select 'Inventory Pricing Records',batch_no,'Not Validated or Validation Errors',count(*)
from iminvmast_pric_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no

/*
insert into #t1
select 'Inventory Location Records','Validation Errors',count(*)
from iminvmast_pric_vw
where record_status_1 <> 0
or record_status_2 <> 0
group by batch_no
*/

insert into #t1
select 'Inventory Pricing Records',batch_no,'Validated / Not Processed',count(*)
from iminvmast_pric_vw
where record_status_1 = 0
and record_status_2 = 0
group by batch_no


insert into #t1
select 'Inventory Pricing Records',batch_no,'Processed',count(*)
from iminvmast_pric_vw
where process_status = 1
group by batch_no

insert into #t1
select 'Inventory Pricing Records',batch_no,'Total',count(*)
from iminvmast_pric_vw
group by batch_no

-------------
insert into #t1
select 		'Sales Order Header Records',
			batch_no,
			'Not Validated or Validation Errors',
			count(*)
from 		imsoe_hdr_vw
where		process_status = 0
group by 	batch_no


insert into #t1
select 		'Sales Order Header Records',
			batch_no,
			'Validated / Not Processed',
			count(*)
from 		imsoe_hdr_vw
where 		record_status_1 = 0
and 		record_status_2 = 0
and 		process_status = 0
group by 	batch_no


insert into #t1
select 		'Sales Order Header Records',
			batch_no,
			'Processed',
			count(*)
from 		imsoe_hdr_vw
where 		process_status = 1
group by 	batch_no

insert into #t1
select 		'Sales Order Header Records',
			batch_no,
			'Total',
			count(*)
from 		imsoe_hdr_vw
group by 	batch_no

-------------
insert into #t1
select 		'Sales Order Line Records',
			batch_no,
			'Not Validated or Validation Errors',
			count(*)
from 		imsoe_line_vw
where		process_status = 0
group by 	batch_no


insert into #t1
select 		'Sales Order Line Records',
			batch_no,
			'Validated / Not Processed',
			count(*)
from 		imsoe_line_vw
where 		record_status_1 = 0
and 		record_status_2 = 0
and 		process_status = 0
group by 	batch_no


insert into #t1
select 		'Sales Order Line Records',
			batch_no,
			'Processed',
			count(*)
from 		imsoe_line_vw
where 		process_status = 1
group by 	batch_no

insert into #t1
select 		'Sales Order Line Records',
			batch_no,
			'Total',
			count(*)
from 		imsoe_line_vw
group by 	batch_no



select * from #t1


GO
GRANT EXECUTE ON  [dbo].[imInvTabSum_sp] TO [public]
GO
