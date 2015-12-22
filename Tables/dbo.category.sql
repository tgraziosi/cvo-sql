CREATE TABLE [dbo].[category]
(
[timestamp] [timestamp] NOT NULL,
[kys] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[cycle_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_category_insupd] ON [dbo].[category]   FOR INSERT, UPDATE  AS 
BEGIN
	DECLARE @kys_id varchar(10),  
            @SenderID varchar(32)

	Declare @send_document_flag char(1)  -- rev 1
                      
                     select @send_document_flag = 'N'

	IF Exists( SELECT * 
		FROM 	config  
   		WHERE 	flag = 'EAI' and
			value_str = 'Y')
                    
	BEGIN	--EAI enabled
	                     		 
		IF ((Exists( select *
			from inserted i, deleted d
			where 	(i.kys <> d.kys) or 
				(i.description <> d.description) or 
				(i.void <> d.void))) or (not exists( select 'X' from deleted )))
			
		BEGIN	--Location has been changed, send data to Front Office
			select @send_document_flag = 'Y'
		END
		 ELSE 
		BEGIN
			If Update(kys) or Update(description) or Update(void) begin
				select @send_document_flag = 'Y'
			end
		END
	
		If @send_document_flag = 'Y' begin

			select @SenderID = ddid
			 from smcomp_vw

			--Case of Update or insert
			select @kys_id = isnull((select min(kys) from inserted),'')

			while @kys_id <> '' 	--while loop for customer
			begin
				if (@kys_id > '')
					exec EAI_Send_sp 'PartPriceClass', @kys_id, 'BO', 0, @SenderID 

				--Get the next location
				select @kys_id = isnull((select min(kys) 
						from inserted
						where kys > @kys_id),'')
			END	--End while loop
		END
	END
END


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t500delcat] ON [dbo].[category] 
 FOR DELETE 
AS
begin
if exists (select * from config where flag='TRIG_DEL_CAT' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 73599, 'You Can Not Delete A CATEGORY!' 
	return
	end
end

GO
CREATE UNIQUE CLUSTERED INDEX [cat1] ON [dbo].[category] ([kys]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[category] TO [public]
GO
GRANT SELECT ON  [dbo].[category] TO [public]
GO
GRANT INSERT ON  [dbo].[category] TO [public]
GO
GRANT DELETE ON  [dbo].[category] TO [public]
GO
GRANT UPDATE ON  [dbo].[category] TO [public]
GO
