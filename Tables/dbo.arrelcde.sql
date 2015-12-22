CREATE TABLE [dbo].[arrelcde]
(
[timestamp] [timestamp] NOT NULL,
[tiered_flag] [smallint] NOT NULL,
[relation_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label2] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label3] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label4] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label5] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label6] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label7] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label8] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label9] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tier_label10] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_by_date] [datetime] NULL,
[modified_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[arrelcde_del_trg]
ON [dbo].[arrelcde]
FOR DELETE
AS
BEGIN
 DELETE arnarel 
	FROM arnarel, deleted
 WHERE arnarel.relation_code = deleted.relation_code

	IF @@ROWCOUNT = 0
	BEGIN

		DELETE artierrl
		FROM artierrl, deleted
		WHERE artierrl.relation_code = deleted.relation_code
	END

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[arrelcde_ins_trg] ON [dbo].[arrelcde] FOR INSERT
AS
BEGIN

 declare @last_code char(8),
 @relation_code char(8),
 @rtn_status int
 
 SELECT @relation_code = ' '
 WHILE 1 = 1
 BEGIN

		select @last_code = @relation_code
		
		SELECT	@relation_code = MIN(relation_code)
		FROM	inserted
		WHERE 	tiered_flag != 0 
 AND 	relation_code > @last_code
		
		 

 IF ( (@@ROWCOUNT <= 0) OR ( @relation_code IS NULL) )
 BREAK

 EXEC @rtn_status = arbldrel_sp @relation_code

 IF @rtn_status != 0 
 BEGIN
 
 RETURN
 END
 END
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[arrelcde_upd_trg] ON [dbo].[arrelcde] FOR UPDATE
AS
BEGIN
 IF UPDATE(tiered_flag)
 BEGIN
 
 DECLARE @last_code char(8),
 @relation_code char(8),
			@rtn_status int
 
 DELETE artierrl
 FROM artierrl, deleted
 WHERE artierrl.relation_code = deleted.relation_code
 
 SELECT @relation_code = ' '
 WHILE 1 = 1
 BEGIN
			SELECT @last_code = @relation_code

			SELECT	@relation_code = MIN(relation_code)
			FROM	inserted
			WHERE	relation_code > @last_code
			AND	tiered_flag != 0
			
			
 
 IF ( (@@ROWCOUNT <= 0) OR (@relation_code IS NULL) )
 BREAK




	 EXEC @rtn_status = arbldrel_sp @relation_code
				 IF @rtn_status != 0 
				 BEGIN
					
					RETURN
				 END


 END
 END

 IF UPDATE ( relation_code )
 BEGIN
		SET ROWCOUNT 10000
 
		WHILE 1 = 1
		BEGIN
	 UPDATE arnarel
	 SET relation_code = inserted.relation_code
	 FROM arnarel, deleted, inserted
	 WHERE deleted.relation_code = arnarel.relation_code

			IF @@ROWCOUNT < 10000
				BREAK
		END
	
 END
	SET ROWCOUNT 0
END
GO
CREATE UNIQUE CLUSTERED INDEX [arrelcde_ind_0] ON [dbo].[arrelcde] ([relation_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arrelcde] TO [public]
GO
GRANT SELECT ON  [dbo].[arrelcde] TO [public]
GO
GRANT INSERT ON  [dbo].[arrelcde] TO [public]
GO
GRANT DELETE ON  [dbo].[arrelcde] TO [public]
GO
GRANT UPDATE ON  [dbo].[arrelcde] TO [public]
GO
