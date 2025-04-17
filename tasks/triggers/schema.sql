create table students (
    id serial primary key,
    first_name text,
    last_name text,
    group_id int references student_groups(id)
);

create table student_groups (
    id serial primary key,
    name text
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

