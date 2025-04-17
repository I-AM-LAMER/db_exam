create table flights (
    id serial primary key,
    model text not null,
    destination text not null,
    time_out timestamp,
    time_in timestamp
);

-- passengers — список пассажиров
create table passengers (
    id serial primary key,
    name text not null
);

-- seats — кто где сидел
create table seats (
    id serial primary key,
    passenger_id int not null references passengers(id),
    flight_id int not null references flights(id),
    seat text not null
);

-- coordinates — для задачи с вектором
create table coordinates (
    id serial primary key,
    x float,
    y float
);

insert into coordinates (x, y) values
    (3, 4),   -- длина = 5
    (0, null),  -- интерпретируется как (0, 0) → длина = 0
    (5, null),  -- интерпретируется как (5, 0) → длина = 5
    (null, 12); -- интерпретируется как (0, 12) → длина = 12

insert into flights (id, model, destination, time_out, time_in) values
    (1, 'Airbus A320', 'Moscow', '2025-04-16 22:00', '2025-04-17 01:00'),  -- прилёт на след. сутки, позже по времени
    (2, 'Boeing 737', 'Paris', '2025-04-16 23:30', '2025-04-17 01:10'),    -- тоже на след. сутки
    (3, 'Boeing 737', 'Berlin', '2025-04-16 20:00', '2025-04-16 22:00'),  -- в тот же день
    (4, 'Airbus A320', 'Paris', '2025-04-16 23:00', '2025-04-17 01:00');  -- для проверки модели и города

insert into passengers (id, name) values
    (1, 'ivan ivanov'),
    (2, 'petr petrov'),
    (3, 'anna sidorova');


insert into seats (passenger_id, flight_id, seat) values
    (1, 1, '12A'),
    (1, 2, '12A'),  -- ivan дважды сидел на 12A
    (1, 3, '10B'),
    (2, 2, '14C'),
    (2, 3, '14C'),  -- petr тоже дважды на одном месте
    (3, 1, '7A'),
    (3, 2, '8A'),
    (3, 3, '7A');

create table student_groups (
    id serial primary key,
    name text
);

create table students (
    id serial primary key,
    first_name text,
    last_name text,
    group_id int references student_groups(id)
);

create table disciplines (
    id serial primary key,
    name text
);

create table schedule (
    id serial primary key,
    discipline_id int references disciplines(id),
    group_id int references student_groups(id),
    time_start timestamp,
    time_end timestamp
);

create table notifications (
    id serial primary key,
    student_id int references students(id),
    created_at timestamp default now(),
    message text,
    is_read boolean default false
);

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


create or replace function notify_schedule_update()
returns trigger as $$
declare
    student record;
    disc_name text;
begin
    if new.time_start <> old.time_start or new.time_end <> old.time_end then
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
    end if;

    return new;
end;
$$ language plpgsql;

create trigger trg_notify_schedule_update
after update on schedule
for each row
execute function notify_schedule_update();


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
