import { AsyncPipe, CommonModule, DatePipe } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { EventService } from '../../services/event-service';
import { CampusEvent } from '../../interfaces/event';
import { BehaviorSubject, finalize, map, Observable } from 'rxjs';
import { Auth } from '../../../auth/services/auth';

@Component({
  selector: 'app-event-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, DatePipe, AsyncPipe],
  templateUrl: './event-detail.html',
  styleUrl: './event-detail.css',
})
export class EventDetail implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly eventService = inject(EventService);
  readonly auth = inject(Auth);

  private readonly eventSubject = new BehaviorSubject<CampusEvent | undefined>(undefined);
  selectedEvent$: Observable<CampusEvent | undefined> = this.eventSubject.asObservable();

  private readonly loadingSubject = new BehaviorSubject<boolean>(true);
  isLoading$: Observable<boolean> = this.loadingSubject.asObservable();
  isDeleting = false;

  hasUserRsvped$: Observable<boolean> = this.selectedEvent$.pipe(map(e => !!e?.hasUserRsvped));
  isPastEvent$: Observable<boolean> = this.selectedEvent$.pipe(map(e => e ? new Date(e.startsAt).getTime() < Date.now() : false));

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      const idStr = params.get('id');
      const eventId = idStr ? parseInt(idStr, 10) : null;

      if (eventId === null || isNaN(eventId)) {
        this.eventSubject.next(undefined);
        this.loadingSubject.next(false);
        return;
      }

      this.loadEvent(eventId);
    });
  }

  loadEvent(id: number): void {
    this.loadingSubject.next(true);
    this.eventService.getEventById(id).pipe(
      finalize(() => this.loadingSubject.next(false))
    ).subscribe({
      next: (event) => {
        this.eventSubject.next(event);
      },
      error: (err) => {
        console.error('Error loading event:', err);
        this.eventSubject.next(undefined);
      }
    });
  }

  onRsvp(): void {
    const event = this.eventSubject.value;
    if (!event) return;

    this.eventService.rsvp(event.id).subscribe({
      next: () => {
        this.loadEvent(event.id);
      },
      error: (err) => {
        console.error('RSVP failed', err);
        if (err.status === 401) {
          alert('Be kell jelentkezned a jelentkezéshez!');
        }
      }
    });
  }

  onCancelRsvp(): void {
    const event = this.eventSubject.value;
    if (!event) return;

    this.eventService.cancelRsvp(event.id).subscribe({
      next: () => {
        this.loadEvent(event.id);
      },
      error: (err) => {
        console.error('Cancel RSVP failed', err);
        alert('Hiba történt a jelentkezés lemondásakor');
      }
    });
  }

  onDeleteEvent(): void {
    const event = this.eventSubject.value;

    if (!event || !this.isCreator(event) || this.isDeleting) {
      return;
    }

    if (!globalThis.confirm('Delete this event? This action cannot be undone.')) {
      return;
    }

    this.isDeleting = true;
    this.eventService.deleteEvent(event.id).subscribe({
      next: () => {
        this.isDeleting = false;
        void this.router.navigate(['/events/my']);
      },
      error: (err) => {
        this.isDeleting = false;
        console.error('Delete event failed', err);
        alert(err?.error?.error || 'Failed to delete event');
      }
    });
  }

  isCreator(event: CampusEvent): boolean {
    const currentUserId = Number(this.auth.currentUser()?.id);
    return Number.isInteger(currentUserId) && event.hostId === currentUserId;
  }
}
