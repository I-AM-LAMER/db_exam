create or replace function notify_schedule_update()
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
            'в расписании для вашей группы произошло изменение занятия ' || disc_name ||
            '. старое время: с ' || old.time_start || ' по ' || old.time_end ||
            ', новое время: с ' || new.time_start || ' по ' || new.time_end
        );
    end loop;

    return new;
end;
$$ language plpgsql;

create trigger trg_notify_schedule_update
after update on schedule
for each row
execute function notify_schedule_update();
