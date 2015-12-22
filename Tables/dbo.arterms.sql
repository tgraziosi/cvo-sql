CREATE TABLE [dbo].[arterms]
(
[timestamp] [timestamp] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[days_due] [smallint] NOT NULL,
[discount_days] [smallint] NOT NULL,
[terms_type] [smallint] NOT NULL,
[discount_prc] [float] NOT NULL,
[min_days_due] [smallint] NOT NULL,
[date_due] [int] NOT NULL,
[date_discount] [int] NOT NULL,
[ddid] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[num_install] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_ARTerms_iu_trg] ON [dbo].[arterms] FOR insert,update
AS
begin

  DECLARE @nResult                int, 
	  @vcPaymentTerm_ID       varchar(8), 
	  @last_PaymentTerm_ID    varchar(8),  
	  @ddid                   varchar(32),
      @Sender         varchar(32)

  if exists(select * from master..sysprocesses 
	      where spid=@@SPID and program_name = 'Epicor EAI')
    return

  select @last_PaymentTerm_ID = ''
  
 select @Sender = ddid
 from smcomp_vw

  while 1=1
  begin

    set rowcount 1
    select @vcPaymentTerm_ID = terms_code, @ddid = ddid
    from inserted
    where terms_code > @last_PaymentTerm_ID
    order by terms_code

    if @@ROWCOUNT <= 0 
      BREAK
    
    set rowcount 0

    IF @ddid IS NULL
    BEGIN
	SELECT @ddid = REPLACE(CONVERT(varchar(36),NEWID()),'-','')

	UPDATE arterms
    	SET    ddid = @ddid
    	WHERE  arterms.terms_code = @vcPaymentTerm_ID
    END

    exec @nResult = EAI_Send_sp @type = 'PaymentTerm', @data = @ddid, @source = 'BO', @action = 1,  @SenderID = @Sender

    select @last_PaymentTerm_ID = @vcPaymentTerm_ID
  end
end
GO
CREATE NONCLUSTERED INDEX [EAI_Integration] ON [dbo].[arterms] ([ddid]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arterms_ind_0] ON [dbo].[arterms] ([terms_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arterms] TO [public]
GO
GRANT SELECT ON  [dbo].[arterms] TO [public]
GO
GRANT INSERT ON  [dbo].[arterms] TO [public]
GO
GRANT DELETE ON  [dbo].[arterms] TO [public]
GO
GRANT UPDATE ON  [dbo].[arterms] TO [public]
GO
