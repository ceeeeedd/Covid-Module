--Covid Module v3

declare @From datetime
declare @To datetime
set @From = '07/01/2020'
set @To = '10/29/2020'

select distinct temp.*, covid_module_id = newid(), dumped_datetime = getdate()
from
(
SELECT DISTINCT
app.appointment_id,
--reg.created_date_time AS Registration_Created_Date_Time,
app.created_date_time AS Appointment_Created_Date_Time,
app.reference_number,
reg.patient_complete_name AS Patient_Name,
reg.age AS Age,
gen.gender AS Gender,
addr.municipality_city,

case when app.created_date_time = (select top 1 a.created_date_time from opr.opr_appointments a where a.transaction_id = reg.transaction_id order by a.created_date_time) then 'New' else 'Returning' end as Patient_Type,

CASE WHEN covid.drive_thru_flag = '1' THEN 'Drive-thru'
	 WHEN covid.drive_thru_flag = '0' THEN 'On-site'
	 ELSE '' END AS Availment_Type,

csa.covid_item_name AS Item_Name,
(select payment_mode_name from opr.opr_payment_mode_ref a where a.payment_mode_id = covid.payment_mode) as Payment_Mode,
case when covid.paid_flag = 1 then 'Paid' when covid.paid_flag = 0 then 'Not Paid' else null end as Paid_status,
isnull(pay.payment_method, '') as Payment_Method,
--pay.amount,
csa.net_amount,
case when app.slot_updated_flag is null then 'Completed'
	 --when covid.paid_flag = 1 and app.slot_updated_flag is null then 'Completed'
	 when app.slot_updated_flag = 1 then 'Cancelled'
	 else '' end as Appointment_Status,

CASE WHEN covid.self_referral_flag = '1' then 'Yes'
	 WHEN covid.self_referral_flag = '0' then 'No'
	 ELSE NULL END AS Self_Referral
		
from opr.opr_appointments app
		inner join opr.covid_appointments covid on app.appointment_id = covid.appointment_id
		inner join opr.opr_transactions trans on app.transaction_id = trans.transaction_id
		inner join opr.opr_registrations reg on app.transaction_id = reg.transaction_id
		inner join opr.opr_address addr on reg.registration_detail_id = addr.registration_detail_id and addr.address_type_id =1
		inner join ols.gender_ref gen on reg.gender_id = gen.gender_ref_id
		left outer join ols.civil_status_ref csr on reg.civil_status_id = csr.civil_status_ref_id
		left join opr.opr_payments pay on pay.appointment_id = app.appointment_id

		inner join opr.covid_patient_type pt on covid.patient_type_id = pt.covid_patient_type_id
		inner join opr.covid_schedule_appointments csa on app.appointment_id = csa.appointment_id

where
CAST(CONVERT(VARCHAR(10),app.created_date_time,101) as SMALLDATETIME) >= CAST(CONVERT(VARCHAR(10),@From,101) as SMALLDATETIME) and	
CAST(CONVERT(VARCHAR(10),app.created_date_time,101) as SMALLDATETIME) <= CAST(CONVERT(VARCHAR(10),@To,101) as SMALLDATETIME)
--app.created_date_time BETWEEN '07/01/2020' AND '07/31/2020'
and covid.drive_thru_flag IS NOT NULL
and trans.confirm_flag = 1
and addr.address_type_id = 1
and app.appointment_type = 'covid'

--ORDER BY app.created_date_time
) as temp
order by temp.Appointment_Created_Date_Time