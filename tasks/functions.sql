create or replace function count_length(x float, y float)
returns float as
$$
begin
	return sqrt(coalesce(x, 0)^2 + coalesce(y, 0)^2);
end;
$$ language plpgsql;

create or replace function is_plane_flied(model_ text, city_ text)
returns boolean as 
$$
begin
	return exists (
		select model, destination from flights
		where model = model_ and destination = city_
	);
end;
$$ language plpgsql;

create or replace function is_arrived_next_day(id_ int)
returns boolean as
$$
declare 
	dep_time timestamp;
	arr_time timestamp;
begin
	select time_out, time_in into dep_time, arr_time from flights
	where id = id_

	IF arr_time IS NULL OR dep_time IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN 
        date_trunc('day', arr_time) = date_trunc('day', dep_time + interval '1 day')
        AND EXTRACT(HOUR FROM arr_time) < EXTRACT(HOUR FROM dep_time);
end;
$$ language plpgsql;

create or replace function most_used_seat(passenger_id int)
returns text as $$
declare
    result text;
begin
    select seat into result
    from seats
    where passenger_id = most_used_seat.passenger_id
    group by seat
    having count(*) > 1
    order by count(*) desc
    limit 1;

    return result;
end;
$$ language plpgsql;

create or replace function has_duplicate_seat(passenger_id int)
returns boolean as $$
begin
    return exists (
        select seat
        from seats
        where passenger_id = has_duplicate_seat.passenger_id
        group by seat
        having count(*) > 1
    );
end;
$$ language plpgsql;
