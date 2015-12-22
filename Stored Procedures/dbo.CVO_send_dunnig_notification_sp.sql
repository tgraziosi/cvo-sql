SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Object:      Procedure  CVO_send_dunnig_notification_sp  
Source file: CVO_send_dunnig_notification_sp.sql
Author:	Bruce Bishop	
Created:	 09/2/2011
Called by:  , 
Copyright:   Epicor Software 2010.  All rights reserved.  
*/

Create  PROCEDURE [dbo].[CVO_send_dunnig_notification_sp]

AS

	DECLARE @from_loc	VARCHAR(10),
			@to_loc		VARCHAR(10),
			@main_loc	VARCHAR(10),
			@attention	VARCHAR(15),
			@qty		VARCHAR(12),
			@part_no	VARCHAR(30),
			@collection	VARCHAR(10),
			@model		VARCHAR(40),
			@color		VARCHAR(40),
			@size		VARCHAR(12),
			@CVO_email VARCHAR(40),
			@cvo_name varchar(40),
			@SUBJECT   VARCHAR(255),
			@MESSAGE   VARCHAR(8000),
			@message_detail varchar (3000),
			@sequence_id int,
			@max_sequence_id int,
			@customer_code   varchar (8),
			@ship_to_code	varchar (8),
			@fin_sequence_id int,
			@fin_max_sequence_id int	

-- create table for email

CREATE TABLE #email
(
ID    int identity(1,1),
customer_code   varchar (8) null,
ship_to_code	varchar (8) null,
doc_ctrl_num	varchar (16) null,
date_due		int null,
attention_name varchar (40) null,
attention_email varchar (255) null,	
message_detail  varchar (3000) null		
)

create index idx_customer_code on  #email (customer_code) with fillfactor = 80
create index idx_ship_to_code on  #email (ship_to_code) with fillfactor = 80


CREATE TABLE #email_fin
(
ID    int identity(1,1),
customer_code   varchar (8) null,
ship_to_code	varchar (8) null,
doc_ctrl_num	varchar (3000) null,
date_due		int null,
attention_name varchar (40) null,
attention_email varchar (255) null,	
message_detail  varchar (3000) null		
)

create index idx_customer_code on  #email_fin (customer_code) with fillfactor = 80
create index idx_ship_to_code on  #email_fin (ship_to_code) with fillfactor = 80


--============================================================================================

insert into #email
(
customer_code,
ship_to_code,
doc_ctrl_num,
date_due,
attention_name,
attention_email,
message_detail
)
select 
a.customer_code,
a.ship_to_code,
a.doc_ctrl_num,
a.date_due,
m.attention_name,
m.attention_email,
''
from artrx_all a(nolock) 
join  armaster_all m (nolock) on m.customer_code = a.customer_code and m.ship_to_code = a.ship_to_code
join ardngpdt d (nolock) on m.dunning_group_id = d.group_id
where m.dunning_group_id = 'EMAIL'
and a.trx_type = 2031
-- for testing after uncomment line below and comment out line below that
and a.date_due < datediff(dd, '1/1/1753', getdate()) + 639906 
--and a.date_due - isnull(d.separation_days,0)<= datediff(dd, '1/1/1753', getdate()) + 639906 
order by 
a.customer_code,
a.ship_to_code,
a.doc_ctrl_num

-- obtain message
select @sequence_id = min(sequence_id), @max_sequence_id = max(sequence_id) from ardnmsdt (nolock)
select @message_detail = ''

WHILE (@sequence_id <= @max_sequence_id )  
		Begin
			
		SELECT @message_detail = @message_detail + isnull(message_detail,'')+'.  '
		from ardnmsdt (nolock) 
		where message_id = 'EMAIL'
		and sequence_id = @sequence_id

		Select @sequence_id = @sequence_id + 1

		End	-- end of While (1=1)
		

update #email set message_detail = @message_detail

insert into #email_fin
(
customer_code,
ship_to_code,
attention_name,
attention_email,
message_detail,
date_due
)
select 
customer_code,
ship_to_code,
attention_name,
attention_email,
message_detail,
min(date_due)
from #email
group by 
customer_code,
ship_to_code,
attention_name,
attention_email,
message_detail

--====================================================
select @sequence_id = 0, @max_sequence_id = 0
select @sequence_id = min(ID), @max_sequence_id = max(ID) 
from #email_fin (nolock)

select @message_detail = ''


WHILE (@sequence_id <= @max_sequence_id )  
		Begin
		
			
		select @customer_code = customer_code, @ship_to_code = isnull(ship_to_code, '')
		from #email_fin (nolock)
		where ID = @sequence_id

		select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID) 
		from #email (nolock)
		where customer_code = @customer_code
		and ship_to_code = @ship_to_code
	
			WHILE (@fin_sequence_id <= @fin_max_sequence_id )  
			Begin
		
			SELECT @message_detail = @message_detail + isnull(doc_ctrl_num,'')+',  '
			from #email (nolock) 
			where  ID = @fin_sequence_id
			
			Select @fin_sequence_id = @fin_sequence_id + 1
			end 

		Update 	#email_fin set doc_ctrl_num = @message_detail
	
		Select @sequence_id = @sequence_id + 1
		End	-- end of While (1=1)

update #email_fin set doc_ctrl_num = @message_detail 


/*
sp_send_dbmail [ [ @profile_name = ] 'profile_name' ]
    [ , [ @recipients = ] 'recipients [ ; ...n ]' ]
    [ , [ @copy_recipients = ] 'copy_recipient [ ; ...n ]' ]
    [ , [ @blind_copy_recipients = ] 'blind_copy_recipient [ ; ...n ]' ]
    [ , [ @subject = ] 'subject' ] 
    [ , [ @body = ] 'body' ] 
    [ , [ @body_format = ] 'body_format' ]
    [ , [ @importance = ] 'importance' ]
    [ , [ @sensitivity = ] 'sensitivity' ]
    [ , [ @file_attachments = ] 'attachment [ ; ...n ]' ]
    [ , [ @query = ] 'query' ]
    [ , [ @execute_query_database = ] 'execute_query_database' ]
    [ , [ @attach_query_result_as_file = ] attach_query_result_as_file ]
    [ , [ @query_attachment_filename = ] query_attachment_filename ]
    [ , [ @query_result_header = ] query_result_header ]
    [ , [ @query_result_width = ] query_result_width ]
    [ , [ @query_result_separator = ] 'query_result_separator' ]
    [ , [ @exclude_query_output = ] exclude_query_output ]
    [ , [ @append_query_error = ] append_query_error ]
    [ , [ @query_no_truncate = ] query_no_truncate ]
    [ , [ @mailitem_id = ] mailitem_id ] [ OUTPUT ]
*/


	BEGIN
		SET @SUBJECT = 'ClearVision Past Due Notification'
		SET @MESSAGE = ''

		select @sequence_id = 0, @max_sequence_id = 0
-- obtain message
		select @sequence_id = min(ID), @max_sequence_id = max(ID) from #email_fin (nolock)
		select @message_detail = ''

		WHILE (@sequence_id <= @max_sequence_id )  
		Begin
			
		SELECT @CVO_email = attention_email, @attention = attention_name
		From #email_fin 
		where ID = @sequence_id
		
		IF (@CVO_email IS NOT NULL) AND (@CVO_email != '')
		BEGIN
			SELECT @MESSAGE = 'Attention ' + @attention + ': <BR><BR>'


			SELECT @MESSAGE = @MESSAGE + message_detail + ': <BR><BR> '
			From #email_fin
			where ID = @sequence_id

			SELECT @MESSAGE = @MESSAGE + 'The Following Invoice(s) are Past Due' + ': <BR><BR> '


			SELECT @MESSAGE = @MESSAGE + doc_ctrl_num 
			From #email_fin
			where ID = @sequence_id
				
			SELECT @MESSAGE = @MESSAGE + '<BR>Please Accounts Receivable department if you have any questions. <BR><BR>'
			SELECT @MESSAGE = @MESSAGE + '<I>This is an automated e-mail, please do not respond. </I> '

			--select @CVO_email = 'tmcgrady@epicor.com'			-- For Testing Only

			EXEC msdb.dbo.sp_send_dbmail	@profile_name	=  'WMS_1',
											@recipients		= @CVO_email, 
											@subject		= @SUBJECT, 
											@body			= @MESSAGE,
											@body_format	= 'HTML',
											@importance		= 'HIGH';

		END	
		

		Select @sequence_id = @sequence_id + 1

		End	-- end of While (1=1)					
	END




-- Permissions
drop table #email
drop table #email_fin


GO
GRANT EXECUTE ON  [dbo].[CVO_send_dunnig_notification_sp] TO [public]
GO
