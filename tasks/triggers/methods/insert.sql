create or replace function notify_schedule_insert()
returns trigger as $$
declare
    student record;
    disc_name text;
begin
    select name into disc_name from disciplines where id = new.discipline_id;

    for student in
        select id from students where group_id = new.group_id
    loop
        insert into notifications(student_id, message)
        values (
            student.id,
            'в расписании для вашей группы добавлено новое занятие ' || disc_name ||
            ', которое пройдет с ' || new.time_start || ' по ' || new.time_end
        );
    end loop;

    return new;
end;
$$ language plpgsql;

create trigger trg_notify_schedule_insert
after insert on schedule
for each row
execute function notify_schedule_insert();
