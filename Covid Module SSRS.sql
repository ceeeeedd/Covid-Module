
SELECT DISTINCT
--reg.created_date_time AS Registration_Created_Date_Time,
app.created_date_time AS Appointment_Created_Date_Time,
app.reference_number,
reg.patient_complete_name AS Patient_Name,
reg.age AS Age,
gen.gender AS Gender,

(select count(distinct reference_number) as visit_count from [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_appointments a
where a.transaction_id = app.transaction_id
and a.appointment_type = 'covid'
) as visit_count,

case
--when (select count(distinct reference_number) as visit_count from opr.opr_appointments a
--where a.transaction_id = app.transaction_id
--and a.appointment_type = 'covid'
--and a.slot_updated_flag is null) = 0 then 'Cancelled' 
--when (select count(distinct reference_number) as visit_count from [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_appointments a
--where a.transaction_id = app.transaction_id
--and a.appointment_type = 'covid') <= 1 then 'New' 
--else 'Returning' end  as Patient_Type,

when app.created_date_time = (select top 1 a.created_date_time from [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_appointments a 
where a.transaction_id = reg.transaction_id order by a.created_date_time) 
then 'New' else 'Returning' end as Patient_Type,

--CASE WHEN reg.created_date_time = reg.lu_date_time THEN 'New'
--	 WHEN reg.created_date_time <= reg.lu_date_time THEN 'Returning'
--	 ELSE NULL END AS Patient_Type,

CASE WHEN covid.drive_thru_flag = '1' THEN 'Drive-thru'
	 WHEN covid.drive_thru_flag = '0' THEN 'On-site'
	 ELSE '' END AS Availment_Type,

csa.covid_item_name AS Item_Name,
(select payment_mode_name from [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_payment_mode_ref a where a.payment_mode_id = covid.payment_mode) as Payment_Mode,
case when covid.paid_flag = 1 then 'Paid' when covid.paid_flag = 0 then 'Not Paid' else null end as Paid_status,
isnull(pay.payment_method, '') as Payment_Method,
--pay.amount,
case when app.slot_updated_flag is null then 'Completed'
	 --when covid.paid_flag = 1 and app.slot_updated_flag is null then 'Completed'
	 when app.slot_updated_flag = 1 then 'Cancelled'
	 else '' end as Appointment_Status,

CASE WHEN covid.self_referral_flag = '1' then 'Yes'
	 WHEN covid.self_referral_flag = '0' then 'No'
	 ELSE NULL END AS Self_Referral
		
from [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_appointments app
		inner join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.covid_appointments covid on app.appointment_id = covid.appointment_id
		inner join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_transactions trans on app.transaction_id = trans.transaction_id
		inner join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_registrations reg on app.transaction_id = reg.transaction_id
		inner join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_address addr on reg.registration_detail_id = addr.registration_detail_id and addr.address_type_id =1
		inner join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.ols.gender_ref gen on reg.gender_id = gen.gender_ref_id
		left outer join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.ols.civil_status_ref csr on reg.civil_status_id = csr.civil_status_ref_id
		left join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.opr_payments pay on pay.appointment_id = app.appointment_id

		inner join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.covid_patient_type pt on covid.patient_type_id = pt.covid_patient_type_id
		inner join [snapshotintegration.cddsrnueh5wh.ap-southeast-1.rds.amazonaws.com,1433].AHMCPortalV2.opr.covid_schedule_appointments csa on app.appointment_id = csa.appointment_id

where
CAST(CONVERT(VARCHAR(10),app.created_date_time,101) as SMALLDATETIME) >= CAST(CONVERT(VARCHAR(10),@From,101) as SMALLDATETIME) and	
CAST(CONVERT(VARCHAR(10),app.created_date_time,101) as SMALLDATETIME) <= CAST(CONVERT(VARCHAR(10),@To,101) as SMALLDATETIME)
--app.created_date_time BETWEEN '07/01/2020' AND '07/31/2020'
and covid.drive_thru_flag IS NOT NULL
and trans.confirm_flag = 1 
and app.appointment_type = 'covid'

ORDER BY app.created_date_time