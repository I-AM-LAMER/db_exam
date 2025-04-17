create or replace function notify_schedule_delete()
returns trigger as $$
declare
    student record;
    disc_name text;
begin
    select name into disc_name from disciplines where id = old.discipline_id;

    for student in
        select id from students where group_id = old.group_id
    loop
        insert into notifications(student_id, message)
        values (
            student.id,
            'в расписании для вашей группы занятие ' || disc_name ||
            ' с ' || old.time_start || ' отменено'
        );
    end loop;

    return old;
end;
$$ language plpgsql;

create trigger trg_notify_schedule_delete
after delete on schedule
for each row
execute function notify_schedule_delete();
