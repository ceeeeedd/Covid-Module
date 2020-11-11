--Testing Center Report
--AmalgaPROD

declare @From datetime
declare @To datetime
set @From = '05/01/2020'
set @To = '05/31/2020'

--Testing Center Report
--AmalgaPROD

select distinct
temp.cpoe_placer_order_id,
temp.cpoe_placer_order_group_id,
temp.patient_id,
temp.creation_visit_id,
temp.patient_visit_id,
temp.placer_order_number,
temp.hn,
temp.patient_name,
temp.actual_visit_date_time,
temp.closure_date_time,
temp.visit_type,
temp.visit_code,
temp.charge_type_rcd,
temp.orderable,
--cd.amount,
isnull((select top 1 case when deleted_date_time is null then amount else 0 end from charge_detail a 
where a.patient_visit_id = temp.patient_visit_id
and a.deleted_date_time is null
and a.item_id in 
(
'135F3211-829E-4E6A-84B2-81C99716C946',	--COVID-19 PCR Test
'6BDA62B9-54E9-45A6-9A8F-FF1274E28FFE',	--COVID-19 PCR Test (Off-site)
'181EE9FD-27D9-44D8-A4B8-0951BA4ECA84',	--COVID-19 PCR TEST (Pre-Employment)
'3866C6A8-505F-460E-A3EA-9ACD7CEDFFFD',	--COVID-19 PCR TEST (Specimen Referral)
'9908D001-8859-4BD4-9050-CF15CD010F63',	--COVID-19 PCR Test (Value-based)
'3325625A-E980-49D1-9668-C358F21B01CD',	--COVID-19 PCR Test (VIP)
'54D45FF8-6C34-4C36-84D8-06BBD8123522',	--COVID-19 PCR Test (Walk-in)
--'2DF58A13-0929-4B2E-A522-DA9A9E535492',	--COVID-19 Specimen Collection, Handling and Transport Fee
'629B3A99-5858-4D12-91E8-31C2AC154F30'	--Rapid COVID-19 Antibody Test
)),(select top 1 case when deleted_date_time is null then amount else 0 end from charge_detail a 
where a.patient_visit_id = (select top 1 patient_visit_id from patient_visit aa where aa.associated_visit_id = temp.patient_visit_id)
and a.deleted_date_time is null
and a.item_id in 
(
'135F3211-829E-4E6A-84B2-81C99716C946',	--COVID-19 PCR Test
'6BDA62B9-54E9-45A6-9A8F-FF1274E28FFE',	--COVID-19 PCR Test (Off-site)
'181EE9FD-27D9-44D8-A4B8-0951BA4ECA84',	--COVID-19 PCR TEST (Pre-Employment)
'3866C6A8-505F-460E-A3EA-9ACD7CEDFFFD',	--COVID-19 PCR TEST (Specimen Referral)
'9908D001-8859-4BD4-9050-CF15CD010F63',	--COVID-19 PCR Test (Value-based)
'3325625A-E980-49D1-9668-C358F21B01CD',	--COVID-19 PCR Test (VIP)
'54D45FF8-6C34-4C36-84D8-06BBD8123522',	--COVID-19 PCR Test (Walk-in)
--'2DF58A13-0929-4B2E-A522-DA9A9E535492',	--COVID-19 Specimen Collection, Handling and Transport Fee
'629B3A99-5858-4D12-91E8-31C2AC154F30'	--Rapid COVID-19 Antibody Test
))) as amount,
temp.creation_date_time,
temp.Verfied,
temp.[Collected/Acquired],
temp.Published,
temp.Completed,
temp.order_owner,
temp.ordering_location,
temp.date_of_birth,
temp.age,
case when temp.age between 0 and 18 then '0-18'
	 when temp.age between 19 and 59 then '19-59'
	 when temp.age >= 60 then '60 above'
	 else null end as [Age Group],
temp.Location,
temp.sex_rcd,
temp.patient_indicator,
temp.created_by,
temp.last_modified_by,
temp.priority,
temp.comments,
temp.patient_type
from
(
select distinct
cpoe.placer_order_number,
cpoe.cpoe_placer_order_id,
cpoe.cpoe_placer_order_group_id,
pv.patient_id,
cpoe.creation_visit_id,
pv.patient_visit_id,
(select visible_patient_id from patient_hospital_usage a where a.patient_id = pv.patient_id) as hn,
pfn.display_name_l as patient_name,
pv.actual_visit_date_time,
pv.closure_date_time,
(select a.name_l from visit_type_ref a where a.visit_type_rcd = pv.visit_type_rcd) as visit_type,
pv.visit_code,
pv.charge_type_rcd,
(select filler_name_l from cpoe_orderable a where a.cpoe_orderable_id = cpoe.cpoe_orderable_id) as orderable,
cpoe.creation_date_time,
(select top 1 a.status_date_time from cpoe_placer_order_status a where a.cpoe_placer_order_id = cpoe.cpoe_placer_order_id and a.cpoe_placer_order_status_rcd = 'ACTIV' order by a.status_date_time desc) as Verfied,
(select top 1 a.status_date_time from cpoe_placer_order_status a where a.cpoe_placer_order_id = cpoe.cpoe_placer_order_id and a.cpoe_placer_order_status_rcd = 'CON' order by a.status_date_time desc) as 'Collected/Acquired',
(select top 1 a.status_date_time from cpoe_placer_order_status a where a.cpoe_placer_order_id = cpoe.cpoe_placer_order_id and a.cpoe_placer_order_status_rcd = 'REPUB' order by a.status_date_time desc) as Published,
(select top 1 a.status_date_time from cpoe_placer_order_status a where a.cpoe_placer_order_id = cpoe.cpoe_placer_order_id and a.cpoe_placer_order_status_rcd = 'COMPL' order by a.status_date_time desc) as Completed,
--(select name_l from cpoe_placer_order_status_ref a where a.cpoe_placer_order_status_rcd = cpos.cpoe_placer_order_status_rcd) as status,
(select a.display_name_l from person_formatted_name_iview a where a.person_id = cpoe.order_owner_employee_id) as order_owner,
--(select top 1 a.name_l from area a where a.area_id = cpos.area_id order by cpos.status_date_time desc) as ordering_location,
(select top 1 a.name_l from area a inner join cpoe_placer_order_status bb on a.area_id = bb.area_id where bb.cpoe_placer_order_id = cpoe.cpoe_placer_order_id order by bb.status_date_time desc) as ordering_location,
(select top 1
				isnull(c.name_l,(select aa.name_l from subregion aa where d.subregion_id = aa.subregion_id))
				from person_address a inner join address b on a.address_id = b.address_id
									  left join subregion c on b.subregion_id = c.subregion_id
									  left join city d on b.city_id = d.city_id
				where a.person_id = pv.patient_id
				and a.person_address_type_rcd = 'H1'
				and a.effective_until_date is null
		) as Location,
pfn.date_of_birth,
cast((DATEDIFF(dd,pfn.date_of_birth,pv.actual_visit_date_time) / 365.25) as int) as age,
case when pfn.sex_rcd = 'M' then 'Male' else 'Female' end as sex_rcd,
(select top 1 b.name_l from person_indicator a inner join person_indicator_ref b on a.person_indicator_rcd = b.person_indicator_rcd where a.person_id = pv.patient_id and a.active_flag = 1 and b.active_status = 'a' and b.visible_code = 'a' order by a.lu_updated desc) as patient_indicator,
--(select top 1 a.display_name_l from person_formatted_name_iview a where a.person_id = cpos.employee_id order by cpos.status_date_time desc) as created_by,
(select top 1 a.display_name_l from person_formatted_name_iview a inner join cpoe_placer_order_status bb on a.person_id = bb.employee_id where bb.cpoe_placer_order_id = cpoe.cpoe_placer_order_id order by bb.status_date_time) as created_by,
(select top 1 a.display_name_l from person_formatted_name_iview a inner join cpoe_placer_order_status bb on a.person_id = bb.employee_id where bb.cpoe_placer_order_id = cpoe.cpoe_placer_order_id order by bb.status_date_time desc) as last_modified_by,

(select a.name_l from cpoe_order_priority_ref a where a.cpoe_order_priority_rcd = cpoe.cpoe_order_priority_rcd) as priority,
cpoe.comments,
case when eei.job_title_name_l = 'Doctor' then 'Doctor'
     when eei.person_id = pv.patient_id then 'Employee'
	 else 'Patient' end as patient_type

from cpoe_placer_order cpoe  inner join (select a.cpoe_placer_order_id, max(status_date_time) as maxdate from cpoe_placer_order a group by a.cpoe_placer_order_id) mdate on cpoe.cpoe_placer_order_id = mdate.cpoe_placer_order_id
							 --left join cpoe_placer_order_group cpog on cpoe.cpoe_placer_order_group_id = cpog.cpoe_placer_order_group_id
							 inner join cpoe_placer_order_status cpos on cpos.cpoe_placer_order_id = cpoe.cpoe_placer_order_id
							 --inner join (select a.cpoe_placer_order_id, max(status_date_time) as maxdate from cpoe_placer_order a group by a.cpoe_placer_order_id) mdate1 on cpos.cpoe_placer_order_id = mdate1.cpoe_placer_order_id
							 inner join patient_visit pv on cpoe.creation_visit_id = pv.patient_visit_id
							 left join person_formatted_name_iview pfn on pv.patient_id = pfn.person_id
							 left join employee_employment_info_view eei on pv.patient_id = eei.person_id
where 
cpoe.cpoe_orderable_id in 
(
'25E27FEA-93FB-11EA-AACD-D89EF393C9E3', --Rapid COVID-19 Antibody Test
'670BB473-9662-11EA-A94B-D89EF393F826', --COVID-19 PCR Test
'388E2B1A-A0A6-11EA-A950-D89EF393F826', --COVID-19 PCR TEST (Specimen Referral)
'C298FFD5-A482-11EA-A952-D89EF393F826', --COVID-19 PCR TEST (Pre-Employment)
'9AA25CA4-E023-11EA-A970-D89EF393F826', --COVID-19 PCR Test (Walk-in)
'23AD7EEA-E025-11EA-A970-D89EF393F826', --COVID-19 PCR Test (VIP)
'D6B53E28-E029-11EA-A970-D89EF393F826', --COVID-19 PCR Test (Value-based)
'BA54E100-FC7F-11EA-A973-D89EF393F826', --COVID-19 PCR Test (Off-site)
'D534CBCE-98DF-11EA-A94D-D89EF393F826', --Anti-SARS-CoV-2 (Total + IgG) by ECLIA
'47785505-CA6E-11EA-A968-D89EF393F826', --Anti-SARS-CoV-2( IgG) by ECLIA
'546D8049-CA6F-11EA-A968-D89EF393F826' --Anti-SARS-CoV-2( Total) by ECLIA
)
and pv.cancelled_date_time is null
and cpoe.cpoe_placer_order_status_rcd not in ('ABORT','CANCL','SUSPE')
--and pv.patient_id = '1D94FCAE-F626-11EA-8D08-78E3B58FDCBD'
--and CAST(CONVERT(VARCHAR(10),cpoe.creation_date_time,101) as SMALLDATETIME) = CAST(CONVERT(VARCHAR(10),@today,101) as SMALLDATETIME)
and CAST(CONVERT(VARCHAR(10),cpoe.creation_date_time,101) as SMALLDATETIME) >= CAST(CONVERT(VARCHAR(10),@From,101) as SMALLDATETIME)
and CAST(CONVERT(VARCHAR(10),cpoe.creation_date_time,101) as SMALLDATETIME) <= CAST(CONVERT(VARCHAR(10),@To,101) as SMALLDATETIME)
and eei.termination_date is null
and pfn.display_name_l is not null
--order by pfn.display_name_l, cpoe.creation_date_time
) as temp --left join charge_detail cd on temp.creation_visit_id = cd.patient_visit_id
--and cd.item_id in
--(
--'135F3211-829E-4E6A-84B2-81C99716C946',	--COVID-19 PCR Test
--'6BDA62B9-54E9-45A6-9A8F-FF1274E28FFE',	--COVID-19 PCR Test (Off-site)
--'181EE9FD-27D9-44D8-A4B8-0951BA4ECA84',	--COVID-19 PCR TEST (Pre-Employment)
--'3866C6A8-505F-460E-A3EA-9ACD7CEDFFFD',	--COVID-19 PCR TEST (Specimen Referral)
--'9908D001-8859-4BD4-9050-CF15CD010F63',	--COVID-19 PCR Test (Value-based)
--'3325625A-E980-49D1-9668-C358F21B01CD',	--COVID-19 PCR Test (VIP)
--'54D45FF8-6C34-4C36-84D8-06BBD8123522',	--COVID-19 PCR Test (Walk-in)
--'2DF58A13-0929-4B2E-A522-DA9A9E535492',	--COVID-19 Specimen Collection, Handling and Transport Fee
--'629B3A99-5858-4D12-91E8-31C2AC154F30',	--Rapid COVID-19 Antibody Test
--'65F0B585-D477-4134-B0C0-6BA1A2F2345D',	--Anti-SARS-CoV-2( IgG) by ECLIA
--'2D7B04B1-4596-4CC6-8EFB-9F2CF1ECB445',	--Anti-SARS-CoV-2( Total) by ECLIA
--'FC99552F-8F33-48B3-A1D4-D2C0D62F0DDE'	--Anti-SARS-CoV-2( Total+IgG) by ECLIA
--)
--where 
--cd.deleted_date_time is null
order by temp.patient_name