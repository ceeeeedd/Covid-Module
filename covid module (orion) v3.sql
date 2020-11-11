declare @From datetime
declare @To datetime
set @From = '05/01/2020'
set @To = getdate()

select distinct
pv.actual_visit_date_time as [Visit Date],
pv.closure_date_time as [Discharge Date],
phu.visible_patient_id as [HN],
pfn.display_name_l as [Patient Name],
cast((DATEDIFF(dd,pfn.date_of_birth,pv.actual_visit_date_time) / 365.25) as int) as Age,
case when pfn.sex_rcd = 'M' then 'Male' else 'Female' end as Gender,
pv.charge_type_rcd as [Charge Type],
pv.visit_type_rcd as [Visit Type Code],
(select name_l from visit_type_ref a where a.visit_type_rcd = pv.visit_type_rcd) as [Visit Type],
pv.visit_code as [Visit Code],
pv.primary_service_rcd as [Primary Service Code],
(select name_l from primary_service_ref a where a.primary_service_rcd = pv.primary_service_rcd) as [Primary Service],
cd.charge_detail_id,
cd.charged_date_time as [Charged Date],
cd.amount as [Charged Amount],
(select name_l from swe_payment_status_ref a where a.swe_payment_status_rcd = cd.payment_status_rcd) as [Paid Status],
i.item_code as [Item Code],
i.name_l as [Item Name],
(select top 1
				isnull(c.name_l,(select aa.name_l from subregion aa where d.subregion_id = aa.subregion_id))
				from person_address a inner join address b on a.address_id = b.address_id
									  left join subregion c on b.subregion_id = c.subregion_id
									  left join city d on b.city_id = d.city_id
				where a.person_id = pv.patient_id
				and a.person_address_type_rcd = 'H1'
				and a.effective_until_date is null
		) as Location,
isnull(case when cd.payment_status_rcd = 'UNP' then 'Unpaid' else p.description_l end,'Self Pay') as [Payment Mode],
case when pv.actual_visit_date_time = (select top 1 a.actual_visit_date_time from patient_visit a where a.patient_id = pv.patient_id order by actual_visit_date_time) then 'New' else 'Returning' end as [Patient Type]
from patient_visit pv left join charge_detail cd on pv.patient_visit_id = cd.patient_visit_id
					  left join person_formatted_name_iview pfn on pv.patient_id = pfn.person_id
					  left join patient_hospital_usage phu on pv.patient_id = phu.patient_id
					  left join item i on cd.item_id = i.item_id
					  left join primary_service_ref psr on pv.primary_service_rcd = psr.primary_service_rcd
					  left join ar_invoice_detail ard on ard.charge_detail_id = cd.charge_detail_id
					  left join ar_invoice ar on ar.ar_invoice_id = ard.ar_invoice_id
					  left join policy p on p.policy_id = ar.policy_id
where
cd.deleted_date_time is null
and pv.cancelled_date_time is null
and ar.transaction_status_rcd not in ('VOI','UNK')
--and pv.patient_id = 'D6190D67-C701-11EA-B393-14B31F267FC3'
--phu.visible_patient_id = '00503400'
and cd.item_id in 
(
'135F3211-829E-4E6A-84B2-81C99716C946',	--COVID-19 PCR Test
'6BDA62B9-54E9-45A6-9A8F-FF1274E28FFE',	--COVID-19 PCR Test (Off-site)
'181EE9FD-27D9-44D8-A4B8-0951BA4ECA84',	--COVID-19 PCR TEST (Pre-Employment)
'3866C6A8-505F-460E-A3EA-9ACD7CEDFFFD',	--COVID-19 PCR TEST (Specimen Referral)
'9908D001-8859-4BD4-9050-CF15CD010F63',	--COVID-19 PCR Test (Value-based)
'3325625A-E980-49D1-9668-C358F21B01CD',	--COVID-19 PCR Test (VIP)
'54D45FF8-6C34-4C36-84D8-06BBD8123522',	--COVID-19 PCR Test (Walk-in)
--'2DF58A13-0929-4B2E-A522-DA9A9E535492',	--COVID-19 Specimen Collection, Handling and Transport Fee
'629B3A99-5858-4D12-91E8-31C2AC154F30',	--Rapid COVID-19 Antibody Test
'65F0B585-D477-4134-B0C0-6BA1A2F2345D',	--Anti-SARS-CoV-2( IgG) by ECLIA
'2D7B04B1-4596-4CC6-8EFB-9F2CF1ECB445',	--Anti-SARS-CoV-2( Total) by ECLIA
'FC99552F-8F33-48B3-A1D4-D2C0D62F0DDE'	--Anti-SARS-CoV-2( Total+IgG) by ECLIA
)
--and CAST(CONVERT(VARCHAR(10),pv.actual_visit_date_time,101) as SMALLDATETIME) >= CAST(CONVERT(VARCHAR(10),@From,101) as SMALLDATETIME)
--and CAST(CONVERT(VARCHAR(10),pv.actual_visit_date_time,101) as SMALLDATETIME) <= CAST(CONVERT(VARCHAR(10),@To,101) as SMALLDATETIME)
and CAST(CONVERT(VARCHAR(10),cd.charged_date_time,101) as SMALLDATETIME) >= CAST(CONVERT(VARCHAR(10),@From,101) as SMALLDATETIME)
and CAST(CONVERT(VARCHAR(10),cd.charged_date_time,101) as SMALLDATETIME) <= CAST(CONVERT(VARCHAR(10),@To,101) as SMALLDATETIME)
order by pv.actual_visit_date_time --, cd.charged_date_time