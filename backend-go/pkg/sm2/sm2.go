// Package sm2 implements the SuperMemo 2 (SM-2) spaced repetition algorithm.
// Reference: https://www.supermemo.com/en/blog/application-of-a-computer-to-improve-the-results-obtained-in-working-with-the-supermemo-method
package sm2

import (
	"math"
	"time"
)

// Result holds the output of a single SM-2 calculation.
type Result struct {
	NextInterval   int
	NewEasiness    float64
	NewRepetitions int
	NextReviewDate time.Time
	IsReset        bool
}

// Calculate performs one SM-2 step.
//
//	quality       – response quality 0–5 (0=blackout, 5=perfect)
//	repetitions   – number of successful repetitions so far
//	easiness      – current ease factor (E-Factor), initial value 2.5, minimum 1.3
//	interval      – current interval in days
func Calculate(quality, repetitions int, easiness float64, interval int) Result {
	if quality < 3 {
		// Failed — reset repetitions and interval
		return Result{
			NextInterval:   1,
			NewEasiness:    easiness,
			NewRepetitions: 0,
			NextReviewDate: time.Now().AddDate(0, 0, 1),
			IsReset:        true,
		}
	}

	// Update ease factor
	newEasiness := easiness + (0.1 - float64(5-quality)*(0.08+float64(5-quality)*0.02))
	if newEasiness < 1.3 {
		newEasiness = 1.3
	}

	// Calculate next interval
	var nextInterval int
	switch repetitions {
	case 0:
		nextInterval = 1
	case 1:
		nextInterval = 6
	default:
		nextInterval = int(math.Round(float64(interval) * newEasiness))
	}

	return Result{
		NextInterval:   nextInterval,
		NewEasiness:    newEasiness,
		NewRepetitions: repetitions + 1,
		NextReviewDate: time.Now().AddDate(0, 0, nextInterval),
		IsReset:        false,
	}
}

// QualityFromScore maps a raw score (0–100) to SM-2 quality (0–5).
func QualityFromScore(score int) int {
	q := score / 20
	if q > 5 {
		return 5
	}
	return q
}

// AdaptiveScore computes a bonus-adjusted score merging raw score and difficulty.
// Merged from Python adaptive engine (simple formula, no external HTTP call).
func AdaptiveScore(rawScore, durationSeconds, difficulty int) float64 {
	base := float64(rawScore)
	diffBonus := float64(difficulty-1) * 2.0
	result := base + diffBonus
	if result > 100 {
		return 100
	}
	return result
}
