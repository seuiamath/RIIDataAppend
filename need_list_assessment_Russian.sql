create view ba_view.RII
as

with Ofm_Urban as(
SELECT 
zipcodea,
CASE
              WHEN TRUNC(ruca30, 0) BETWEEN 7 AND 10
                THEN 'Rural'
              WHEN TRUNC(ruca30, 0) BETWEEN 4 AND 6
                THEN 'Large Rural'
              WHEN TRUNC(ruca30, 0) BETWEEN 2 AND 3
                THEN 'Suburban'
              WHEN TRUNC(ruca30, 0) = 1
                THEN 'Urban'
              END                      AS urban_rural
FROM acquisition.urbanrural_zip 
)
SELECT DISTINCT p.contactid                   AS contactid,
                p.kn_key_name                 AS zenithid,
                p.personid,
                p.firstname                   AS name_first,
                p.lastname                    AS name_last,
                d.prt_addr1                   AS mailing_addr1,
                d.prt_addr2                   AS mailing_addr2,
                d.prt_city                    AS mailing_city,
                d.prt_state                   AS mailing_state,
                d.prt_zip_code                AS mailing_zip,
                'US'                          AS mailing_country,
                c.county,
                c.email,
                c.secondary_email             AS email_secondary,
                CASE
                  WHEN p.phone = '0' OR p.phone = '000000000' OR p.phone = '0000000000'
                    THEN ''
                  ELSE CONCAT('1', REGEXP_REPLACE(p.phone, '[^0-9]'))
                  END                         AS phone,
                CASE
                  WHEN p.mobilephone = '0' OR p.mobilephone = '000000000' OR p.mobilephone = '0000000000'
                    THEN ''
                  ELSE CONCAT('1', REGEXP_REPLACE(p.mobilephone, '[^0-9]'))
                  END                         AS phone_mobile,
                CASE
                  WHEN p.homephone = '0'
                    THEN ''
                  ELSE CONCAT('1', REGEXP_REPLACE(p.homephone, '[^0-9]'))
                  END                         AS phone_home,
                CASE
                  WHEN p.mobilephone != '' AND p.mobilephone != '0' AND p.mobilephone != '000000000'
                         AND p.mobilephone != '0000000000'
                    THEN CONCAT('1', REGEXP_REPLACE(p.mobilephone, '[^0-9]'))
                  WHEN p.mobilephone = '' OR p.mobilephone = '0' OR p.mobilephone = '000000000'
                         OR p.mobilephone = '0000000000'
                    THEN CONCAT('1', REGEXP_REPLACE(p.phone, '[^0-9]'))
                  ELSE CONCAT('1', REGEXP_REPLACE(p.homephone, '[^0-9]'))
                  END                           AS phone_text,
                d.prt_sex                         AS gender,
                c.age,
                CASE
                 WHEN ps_employer_code = '3000' AND ps_hours_type = 'H'
                   THEN 'IP'
                 WHEN ps_employer_code != '3000' AND ps_hours_type = 'H'
                   THEN 'AP'
                 END AS hca_type_employer,
                CASE
                  WHEN SUBSTRING(ps_class, 4, 1) = 'K'
                    THEN 'Kaiser NW (HMO)'
                  WHEN SUBSTRING(ps_class, 4, 1) = 'H'
                    THEN 'Kaiser WA (HMO)'
                  WHEN SUBSTRING(ps_class, 4, 1) = 'P'
                    THEN 'Kaiser WA (POS)'
                  WHEN SUBSTRING(ps_class, 4, 1) = 'T'
                    THEN 'Aetna (PPO)'
                  WHEN SUBSTRING(ps_class, 4, 1) = 'O'
                    THEN 'Kaiser WA (PPO)'
                  WHEN SUBSTRING(ps_class, 4, 1) = 'N'
                    THEN 'None'
                END AS carrier_plan,
                 urban_rural
FROM pstg.person p
  LEFT JOIN acquisition.sf_contact c
    ON p.contactid = c.contactid
  LEFT JOIN hbt.demographic d
    ON p.prt_ss_nbr = d.prt_ss_nbr
  LEFT JOIN Ofm_Urban ct
    ON d.prt_zip_code = ct.zipcodea
  LEFT JOIN hbt.eligibility e
    ON p.prt_ss_nbr = e.ps_ss_nbr
WHERE (                     --MUST HAVE A COMPLETE ADDRESS
  d.prt_addr1 != ''
  AND d.prt_city != ''
  AND d.prt_state != ''
  AND d.prt_zip_code > 0
    OR (                    --OR MUST HAVE A PHONE#
      p.phone != ''
      OR p.mobilephone != ''
      OR p.homephone != ''
      )
    OR (                    --OR MUST HAVE AN EMAIL ADDRESS
      c.email != ''
      OR c.secondary_email != ''
      )
  )
  AND e.ps_date = DATE_TRUNC('month', CURRENT_DATE)
  AND c.communication_language = 'Russian'
  AND SUBSTRING(ps_class, 3, 1) IN ('B', 'R')
  AND ps_hours_type = 'H'
  AND c.opt_out_do_not_contact IS FALSE
  AND upper(left(c.mailingstate, 2)) = 'WA'
  


