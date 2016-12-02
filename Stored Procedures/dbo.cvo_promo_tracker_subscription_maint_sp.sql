SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promo_tracker_subscription_maint_sp]
    (
      @group_name VARCHAR(20) ,
      @Action CHAR(1) ,
      @promo_id VARCHAR(1024) ,
      @promo_level VARCHAR(1024) ,
      @StartDate DATETIME ,
      @EndDate DATETIME = NULL ,
      @Seq INT = NULL ,
      @id INT = NULL
    )
AS
    BEGIN

        SET NOCOUNT ON;

	/*
	 SELECT * into cvo_promo_tracker_subscription_list_bckup_113016 FROM CVO_PROMO_TRACKER_SUBSCRIPTION_LIST
	 DELETE FROM dbo.cvo_promo_tracker_subscription_list WHERE id BETWEEN 16 AND 25


	 EXEC cvo_promo_tracker_subscription_maint_sp 'CIA', 'd', 'SUN SPRING', '','9/2/2016', NULL , 6

	*/
        DECLARE @msg VARCHAR(80);

        IF @Action = 'L'
            RETURN;

        IF @Action = 'A'
            BEGIN

                IF EXISTS ( SELECT  1
                            FROM    cvo_promo_tracker_subscription_list
                            WHERE   Group_Name = @group_name
                                    AND promo_id = @promo_id
                                    AND promo_level = @promo_level
                                    AND start_date = @StartDate
                                    AND ISNULL(end_date, GETDATE()) = ISNULL(@EndDate,
                                                              GETDATE()) )
                    BEGIN
                        SELECT  'Subscription already exists.  Cannot Add.';
                        RETURN;
                    END;
                IF @Seq IS NULL
                    SELECT  @Seq = MAX(ISNULL(Seq_id, 0)) + 10
                    FROM    dbo.cvo_promo_tracker_subscription_list
                    WHERE   Group_Name = @group_name;
                INSERT  dbo.cvo_promo_tracker_subscription_list
                        ( promo_id ,
                          promo_level ,
                          start_date ,
                          end_date ,
                          Group_Name ,
                          Seq_id
                        )
                VALUES  ( @promo_id ,
                          @promo_level ,
                          @StartDate ,
                          @EndDate ,
                          @group_name ,
                          @Seq
		                );
                IF @@ERROR <> 0
                    BEGIN
                        SET @msg = 'Error Adding SUBSCRIPTION';
                    END;
                ELSE
                    BEGIN
                        SET @msg = 'Subscription Added.  Thank you.';
                    END;
				SELECT @msg;
            END;

        IF @Action IN ( 'C', 'D' )
            BEGIN

                SELECT  @id = id
                FROM    cvo_promo_tracker_subscription_list
                WHERE   Group_Name = @group_name
                        AND promo_id = @promo_id
                        AND promo_level = @promo_level
                        AND start_date = @StartDate
                        AND ISNULL(end_date, GETDATE()) = ISNULL(@EndDate,
                                                              GETDATE());
                IF @id IS NULL
                    BEGIN
                        SELECT  'Subscription does not exist. '
                                + CASE WHEN @Action = 'c'
                                       THEN ' Cannot Change.'
                                       WHEN @Action = 'd'
                                       THEN ' Cannot Delete.'
                                       ELSE ''
                                  END;
                        RETURN;
                    END;
                IF @Action = 'D'
                    BEGIN
                        DELETE  FROM dbo.cvo_promo_tracker_subscription_list
                        WHERE   id = @id;
                    END;
                IF @Action = 'C'
                    BEGIN
                        UPDATE  dbo.cvo_promo_tracker_subscription_list
                        SET     promo_id = @promo_id ,
                                promo_level = @promo_level ,
                                start_date = @StartDate ,
                                end_date = @EndDate ,
                                Seq_id = @Seq
                        WHERE   id = @id;
                    END;

                IF @@ERROR <> 0
                    BEGIN
                        SET @msg = 'Error '
                            + CASE WHEN @Action = 'D' THEN 'Deleting'
                                   WHEN @Action = 'C' THEN 'Changing'
                                   ELSE 'Updating'
                              END + ' SUBSCRIPTION';
                    END;
                ELSE
                    BEGIN
                        SET @msg = 'Subscription '
                            + CASE WHEN @Action = 'd' THEN 'Deleted'
                                   WHEN @Action = 'c' THEN 'Changed'
                                   ELSE 'Updated'
                              END + '  Thank you.';
            
                    END;
                SELECT  @msg;

            END;
        RETURN;

    END;

    GRANT ALL ON cvo_promo_tracker_subscription_maint_sp TO PUBLIC;
    
	
GO
