set role jss;
update encounter
set earliest_visit_date_time=earliest_visit_date_time + interval '1 year',
    max_visit_date_time= max_visit_date_time + interval '1 year',
    last_modified_by_id=(select id from users where username = 'sachink@jss'),
    last_modified_date_time=current_timestamp + id * ('1 millisecond' :: interval)
where id in (
742361,
741244,
750874,
1259683,
794516,
928280,
904957,
975432,
1280542,
928267,
904954,
1149363,
794439,
904962,
1260772,
1280536,
1149367,
1231857

    );
